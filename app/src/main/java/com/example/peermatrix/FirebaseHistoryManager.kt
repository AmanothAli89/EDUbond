package com.example.peermatrix

import android.net.Uri
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import com.google.firebase.storage.FirebaseStorage
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.*

object FirebaseHistoryManager {

    private val db = FirebaseFirestore.getInstance()
    private val storage = FirebaseStorage.getInstance()

    /**
     * চ্যাট মেসেজ Firestore-এ সেভ করার জন্য
     */
    fun saveMessage(
        groupId: String,
        senderEmail: String,
        messageText: String,
        fileUrl: String? = null,
        fileType: String? = null,
        fileName: String? = null
    ) {
        val messageData = hashMapOf(
            "groupId" to groupId,
            "senderEmail" to senderEmail,
            "message" to messageText,
            "fileUrl" to fileUrl,
            "fileType" to fileType,
            "fileName" to fileName,
            "timestamp" to System.currentTimeMillis(),
            "seenBy" to listOf(senderEmail) // মেসেজ মেকার নিজে দেখেছে
        )

        db.collection("groups").document(groupId)
            .collection("messages")
            .add(messageData)
            .addOnSuccessListener {
                logActivity(senderEmail, "Sent a message in group: $groupId")
            }
    }

    /**
     * ফাইল আপলোড করে তার লিঙ্ক Firestore-এ সেভ করার জন্য
     */
    fun uploadFile(groupId: String, senderEmail: String, fileUri: Uri, onComplete: (String) -> Unit) {
        val fileName = UUID.randomUUID().toString()
        val ref = storage.reference.child("groups/$groupId/files/$fileName")

        ref.putFile(fileUri)
            .addOnSuccessListener {
                ref.downloadUrl.addOnSuccessListener { uri ->
                    val url = uri.toString()
                    saveMessage(groupId, senderEmail, "Shared a file", url, "document", "Attachment")
                    onComplete(url)
                }
            }
    }

    /**
     * ইউজারের যেকোনো অ্যাক্টিভিটি লগ হিসেবে সেভ রাখা
     */
    fun logActivity(email: String, action: String) {
        val log = hashMapOf(
            "email" to email,
            "action" to action,
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("activity_logs").add(log)
    }

    /**
     * রিয়েল-টাইম মেসেজ লোড করার জন্য
     */
    fun getGroupMessages(groupId: String, onUpdate: (List<Map<String, Any>>) -> Unit) {
        db.collection("groups").document(groupId)
            .collection("messages")
            .orderBy("timestamp")
            .addSnapshotListener { snapshot, e ->
                if (e != null) return@addSnapshotListener
                if (snapshot != null) {
                    val list = mutableListOf<Map<String, Any>>()
                    for (doc in snapshot.documents) {
                        val data = doc.data
                        if (data != null) {
                            val mutableData = data.toMutableMap()
                            mutableData["id"] = doc.id
                            list.add(mutableData)
                        }
                    }
                    onUpdate(list)
                }
            }
    }

    /**
     * কুইজ সেট Firestore-এ সেভ করার জন্য
     */
    fun saveQuizSets(subject: String, quizData: String, onComplete: (Boolean) -> Unit) {
        val data = hashMapOf(
            "subject" to subject,
            "quizJson" to quizData,
            "lastUpdated" to System.currentTimeMillis()
        )
        db.collection("quizzes").document(subject)
            .set(data)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * কুইজ সেট Firestore থেকে লোড করার জন্য
     */
    fun getQuizSets(subject: String, onResult: (String?) -> Unit) {
        db.collection("quizzes").document(subject)
            .get()
            .addOnSuccessListener { doc ->
                onResult(doc.getString("quizJson"))
            }
            .addOnFailureListener { onResult(null) }
    }

    /**
     * সাবজেক্ট লিস্ট Firestore থেকে লোড করা
     */
    fun getGlobalSubjects(onResult: (List<String>) -> Unit) {
        db.collection("subjects").get().addOnSuccessListener { snapshot ->
            val list = snapshot.documents.mapNotNull { doc ->
                doc.getString("name") ?: doc.id // Fallback to document ID if name is missing
            }
            if (list.isEmpty()) {
                val core = listOf(
                    "Software Engineering", "Computer Architecture", "Data Communication",
                    "Microprocessor", "Compiler", "Data Structure", "Database Management System",
                    "Operating System", "Computer Network", "Artificial Intelligence",
                    "Algorithm", "Discrete Mathematics", "গনিত ৯-১০", "উচ্চতর গনিত ৯-১০", "পদার্থবিজ্ঞান ৯-১০", "অর্থনীতি ৯-১০"
                )
                core.forEach { name ->
                    db.collection("subjects").document(name.replace(" ", "_").lowercase())
                        .set(mapOf("name" to name, "type" to "core"))
                }
                onResult(core)
            } else {
                onResult(list.sorted())
            }
        }.addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * নতুন সাবজেক্ট সরাসরি অ্যাড করা (এডমিনের জন্য)
     */
    fun addSubjectGlobally(name: String, onComplete: (Boolean) -> Unit) {
        val id = name.trim().replace(" ", "_").lowercase()
        db.collection("subjects").document(id)
            .set(mapOf("name" to name.trim(), "type" to "admin"))
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * সাবজেক্ট ডিলিট করা
     */
    fun deleteSubjectGlobally(name: String, onComplete: (Boolean) -> Unit) {
        val id = name.trim().replace(" ", "_").lowercase()
        db.collection("subjects").document(id).delete()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * নোটস (Notes/Files) Firestore-এ সেভ করা
     */
    fun addNote(groupId: String, title: String, url: String, type: String, byEmail: String) {
        val noteData = hashMapOf(
            "groupId" to groupId,
            "title" to title,
            "url" to url,
            "type" to type,
            "by" to byEmail,
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("notes").add(noteData)
    }

    /**
     * গ্রুপের সব নোটস লোড করা
     */
    fun getNotes(groupId: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("notes")
            .whereEqualTo("groupId", groupId)
            .orderBy("timestamp", Query.Direction.DESCENDING)
            .get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * সাবজেক্ট লিস্ট Firestore-এ সেভ/আপডেট করা (Legacy)
     */
    fun updateSubjects(subjectsJson: String) {
        val data = hashMapOf("list" to subjectsJson)
        db.collection("app_data").document("subjects").set(data)
    }

    /**
     * নতুন সাবজেক্টের জন্য রিকোয়েস্ট পাঠানো
     */
    fun submitSubjectRequest(subjectName: String, requesterEmail: String, onComplete: (Boolean) -> Unit) {
        val requestId = System.currentTimeMillis().toString()
        val data = hashMapOf(
            "id" to requestId,
            "subject" to subjectName,
            "by" to requesterEmail,
            "status" to "pending",
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("subject_requests").document(requestId).set(data)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * এডমিনের জন্য সব সাবজেক্ট রিকোয়েস্ট লোড করা
     */
    fun getSubjectRequests(onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("subject_requests")
            .orderBy("timestamp", Query.Direction.DESCENDING)
            .get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * সাবজেক্ট রিকোয়েস্টের স্ট্যাটাস আপডেট করা
     */
    fun updateSubjectRequestStatus(requestId: String, status: String, updatedName: String? = null, onComplete: (Boolean) -> Unit) {
        val updates = mutableMapOf<String, Any>("status" to status)
        if (updatedName != null) updates["subject"] = updatedName
        db.collection("subject_requests").document(requestId).update(updates)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * মিটিং লিঙ্ক শেয়ার করার জন্য
     */
    fun saveMeetingLink(groupId: String, senderEmail: String, meetingUrl: String, platform: String) {
        saveMessage(groupId, senderEmail, "Scheduled a $platform meeting", meetingUrl, "meeting", platform)
    }

    /**
     * মেসেজ রিড (Seen) হিসেবে মার্ক করা
     */
    fun markMessageAsRead(groupId: String, messageId: String, email: String) {
        db.collection("groups").document(groupId)
            .collection("messages").document(messageId)
            .update("seenBy", com.google.firebase.firestore.FieldValue.arrayUnion(email))
    }

    /**
     * অ্যাডমিন ক্রেডেনশিয়াল চেক করা (Firestore থেকে)
     */
    fun checkAdminLogin(adminId: String, pass: String, onResult: (Boolean) -> Unit) {
        db.collection("admin_config").document("credentials").get()
            .addOnSuccessListener { doc ->
                if (doc.exists()) {
                    val dbId = doc.getString("id")
                    val dbPass = doc.getString("password")
                    onResult(adminId == dbId && pass == dbPass)
                } else {
                    // যদি ডকুমেন্ট না থাকে তবে ডিফোল্ট হিসেবে চেক করবে (প্রথমবার সেট করার জন্য)
                    onResult(adminId == "Bappy" && pass == "Bappy81")
                }
            }
            .addOnFailureListener { onResult(false) }
    }

    /**
     * মেসেজ ডিলিট (Unsend) করার জন্য
     */
    fun deleteMessage(groupId: String, messageId: String, onComplete: (Boolean) -> Unit) {
        db.collection("groups").document(groupId)
            .collection("messages").document(messageId)
            .delete()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * ডিফল্ট কুইজগুলো Firestore-এ একবার আপলোড করার জন্য
     */
    fun seedDefaultQuizzesToCloud() {
        val subjects = AppStorage.getAllSeededSubjects()
        subjects.forEach { subject ->
            // Seed Quizzes
            db.collection("quizzes").document(subject).get().addOnSuccessListener { doc ->
                if (!doc.exists()) {
                    val defaultData = AppStorage.getDefaultSetsForSubject(subject)
                    if (defaultData != null) {
                        saveQuizSets(subject, defaultData.toString()) { }
                    }
                }
            }
            // Ensure subject exists in the searchable list
            val subId = subject.replace(" ", "_").lowercase()
            db.collection("subjects").document(subId).get().addOnSuccessListener { doc ->
                if (!doc.exists()) {
                    db.collection("subjects").document(subId)
                        .set(mapOf("name" to subject, "type" to "core"))
                }
            }
        }
    }

    /**
     * নির্দিষ্ট গ্রুপের তথ্য লোড করা
     */
    fun getGroupInfo(groupId: String, onResult: (Map<String, Any>?) -> Unit) {
        db.collection("groups").document(groupId).get()
            .addOnSuccessListener { doc -> onResult(doc.data) }
            .addOnFailureListener { onResult(null) }
    }

    /**
     * নতুন গ্রুপ Firestore-এ তৈরি করা
     */
    fun createGroup(subject: String, creatorEmail: String, groupName: String, onComplete: (Boolean) -> Unit) {
        val groupId = "G${System.currentTimeMillis()}"
        val groupData = hashMapOf(
            "id" to groupId,
            "name" to groupName,
            "subject" to subject,
            "createdBy" to creatorEmail,
            "members" to listOf(creatorEmail),
            "teachers" to emptyList<String>(),
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("groups").document(groupId).set(groupData)
            .addOnSuccessListener {
                logActivity(creatorEmail, "Created group: $groupName")
                onComplete(true)
            }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * নির্দিষ্ট সাবজেক্টের সব গ্রুপ লোড করা
     */
    fun getGroupsBySubject(subject: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("groups").whereEqualTo("subject", subject).get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * ইউজারের জয়েন করা সব গ্রুপ লোড করা
     */
    fun getGroupsForUser(email: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("groups").whereArrayContains("members", email).get()
            .addOnSuccessListener { snapshot ->
                val list = snapshot.documents.mapNotNull { doc ->
                    val data = doc.data?.toMutableMap()
                    if (data != null && data["id"] == null) data["id"] = doc.id
                    data
                }.toMutableList()
                
                db.collection("groups").whereArrayContains("teachers", email).get()
                    .addOnSuccessListener { snapshot2 ->
                        val list2 = snapshot2.documents.mapNotNull { doc ->
                            val data = doc.data?.toMutableMap()
                            if (data != null && data["id"] == null) data["id"] = doc.id
                            data
                        }
                        val combined = (list + list2).distinctBy { it["id"] }
                        onResult(combined)
                    }
                    .addOnFailureListener { onResult(list) }
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * গ্রুপে জয়েন রিকোয়েস্ট পাঠানো
     */
    fun requestToJoinGroup(groupId: String, groupName: String, subject: String, requesterEmail: String, onComplete: (Boolean) -> Unit) {
        val requestId = System.currentTimeMillis().toString()
        val data = hashMapOf(
            "id" to requestId,
            "groupId" to groupId,
            "groupName" to groupName,
            "subject" to subject,
            "requester" to requesterEmail,
            "status" to "pending",
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("group_join_requests").document(requestId).set(data)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * নির্দিষ্ট ইউজারের জন্য আসা জয়েন রিকোয়েস্টগুলো লোড করা
     */
    fun getIncomingJoinRequests(email: String, onResult: (List<Map<String, Any>>) -> Unit) {
        getGroupsForUser(email) { groups ->
            val groupIds = groups.mapNotNull { it["id"] as? String }
            if (groupIds.isEmpty()) {
                onResult(emptyList())
                return@getGroupsForUser
            }
            db.collection("group_join_requests")
                .whereIn("groupId", groupIds)
                .whereEqualTo("status", "pending")
                .get()
                .addOnSuccessListener { snapshot ->
                    val list = snapshot.documents.mapNotNull { it.data }
                        .filter { (it["requester"] as? String) != email }
                    onResult(list)
                }
                .addOnFailureListener { onResult(emptyList()) }
        }
    }

    /**
     * ইউজারের পাঠানো সব জয়েন রিকোয়েস্ট লোড করা
     */
    fun getSentRequests(email: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("group_join_requests").whereEqualTo("requester", email).get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * জয়েন রিকোয়েস্ট অ্যাকসেপ্ট করা
     */
    fun acceptJoinRequest(requestId: String, groupId: String, requesterEmail: String, onComplete: (Boolean) -> Unit) {
        db.collection("group_join_requests").document(requestId).update("status", "accepted")
            .addOnSuccessListener {
                db.collection("groups").document(groupId)
                    .update("members", com.google.firebase.firestore.FieldValue.arrayUnion(requesterEmail))
                    .addOnSuccessListener { onComplete(true) }
                    .addOnFailureListener { onComplete(false) }
            }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * জয়েন রিকোয়েস্ট রিজেক্ট করা
     */
    fun rejectJoinRequest(requestId: String, onComplete: (Boolean) -> Unit) {
        db.collection("group_join_requests").document(requestId).update("status", "rejected")
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * ব্লকড টিচারদের লিস্ট লোড করা
     */
    fun getBlockedTeachersGlobally(onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("quiz_attempts").whereEqualTo("blocked", true).get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * টিচারকে আনব্লক করা
     */
    fun unblockTeacherGlobally(email: String, subject: String, onComplete: (Boolean) -> Unit) {
        val attemptId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        db.collection("quiz_attempts").document(attemptId).update("blocked", false, "attempts", 0)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * ইমেইল দিয়ে ইউজারের নাম লোড করা
     */
    fun getUserNameGlobally(email: String, onResult: (String) -> Unit) {
        db.collection("users").whereEqualTo("email", email).get()
            .addOnSuccessListener { snapshot ->
                val name = snapshot.documents.firstOrNull()?.getString("username") ?: email
                onResult(name)
            }
            .addOnFailureListener { onResult(email) }
    }

    /**
     * ইউজারের টিচার/লার্নার রোল Firestore-এ সেভ করা
     */
    fun addSubjectRole(email: String, subject: String, role: String, score: Int = 0, onComplete: (Boolean) -> Unit) {
        val roleId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        val data = hashMapOf(
            "email" to email,
            "subject" to subject,
            "role" to role,
            "score" to score,
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("user_roles").document(roleId).set(data)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * ইউজার কোন সাবজেক্টে কি রোলে আছে তা চেক করা
     */
    fun getUserSubjectRoles(email: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("user_roles").whereEqualTo("email", email).get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * কুইজ অ্যাটেম্পট Firestore-এ সেভ করা এবং ব্লক চেক করা
     */
    fun recordQuizResult(email: String, subject: String, passed: Boolean, onComplete: (Boolean, Boolean) -> Unit) {
        val attemptId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        val ref = db.collection("quiz_attempts").document(attemptId)
        ref.get().addOnSuccessListener { doc ->
            var attempts = (doc.getLong("attempts") ?: 0L).toInt() + 1
            var totalAttempts = (doc.getLong("totalAttempts") ?: 0L).toInt() + 1
            if (passed) attempts = 0 // Reset attempts on pass

            var blocked = doc.getBoolean("blocked") ?: false
            if (!passed && attempts >= 2) blocked = true

            val data = hashMapOf(
                "email" to email,
                "subject" to subject,
                "attempts" to attempts,
                "totalAttempts" to totalAttempts,
                "blocked" to blocked,
                "lastPassed" to passed,
                "timestamp" to System.currentTimeMillis()
            )
            ref.set(data, SetOptions.merge())
                .addOnSuccessListener { onComplete(true, blocked) }
                .addOnFailureListener { onComplete(false, blocked) }
        }
    }

    /**
     * ইউজারের কুইজ স্ট্যাটাস চেক করা
     */
    fun getQuizStatus(email: String, subject: String, onResult: (Map<String, Any>?) -> Unit) {
        val attemptId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        db.collection("quiz_attempts").document(attemptId).get()
            .addOnSuccessListener { doc -> onResult(doc.data) }
            .addOnFailureListener { onResult(null) }
    }

    /**
     * নির্দিষ্ট সাবজেক্টের সব কোয়ালিফাইড টিচার লোড করা
     */
    fun getQualifiedTeachers(subject: String, onResult: (List<String>) -> Unit) {
        db.collection("user_roles")
            .whereEqualTo("subject", subject)
            .whereEqualTo("role", "teacher")
            .get()
            .addOnSuccessListener { snapshot ->
                val list = snapshot.documents.mapNotNull { it.getString("email") }
                onResult(list)
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * সব কোয়ালিফাইড টিচারদের লিস্ট লোড করা (এডমিনের জন্য)
     */
    fun getAllTeachersGlobally(onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("user_roles")
            .whereEqualTo("role", "teacher")
            .get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * টিচার রোল রিমুভ করা
     */
    fun removeTeacherRoleGlobally(email: String, subject: String, onComplete: (Boolean) -> Unit) {
        val roleId = "${email.replace(".", "_")}_${subject.replace(" ", "_")}"
        db.collection("user_roles").document(roleId).delete()
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * টিচারকে গ্রুপে জয়েন করার রিকোয়েস্ট পাঠানো
     */
    fun requestTeacherToJoin(groupId: String, groupName: String, subject: String, requesterEmail: String, teacherEmail: String, onComplete: (Boolean) -> Unit) {
        val requestId = System.currentTimeMillis().toString()
        val data = hashMapOf(
            "id" to requestId,
            "groupId" to groupId,
            "groupName" to groupName,
            "subject" to subject,
            "requester" to requesterEmail,
            "teacher" to teacherEmail,
            "status" to "pending",
            "timestamp" to System.currentTimeMillis()
        )
        db.collection("teacher_group_requests").document(requestId).set(data)
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * গ্রুপ থেকে লিভ করা
     */
    fun leaveGroup(groupId: String, email: String, onComplete: (Boolean) -> Unit) {
        val ref = db.collection("groups").document(groupId)
        ref.get().addOnSuccessListener { doc ->
            if (doc.exists()) {
                val members = (doc.get("members") as? List<String>)?.toMutableList() ?: mutableListOf()
                val teachers = (doc.get("teachers") as? List<String>)?.toMutableList() ?: mutableListOf()
                members.remove(email)
                teachers.remove(email)
                ref.update(mapOf("members" to members, "teachers" to teachers))
                    .addOnSuccessListener { onComplete(true) }
                    .addOnFailureListener { onComplete(false) }
            } else {
                onComplete(false)
            }
        }
    }

    /**
     * টিচার হিসেবে আসা ইনকামিং রিকোয়েস্টগুলো লোড করা
     */
    fun getIncomingTeacherRequests(email: String, onResult: (List<Map<String, Any>>) -> Unit) {
        db.collection("teacher_group_requests")
            .whereEqualTo("teacher", email)
            .whereEqualTo("status", "pending")
            .get()
            .addOnSuccessListener { snapshot ->
                onResult(snapshot.documents.mapNotNull { it.data })
            }
            .addOnFailureListener { onResult(emptyList()) }
    }

    /**
     * টিচার রিকোয়েস্ট অ্যাকসেপ্ট করা
     */
    fun acceptTeacherRequest(requestId: String, groupId: String, teacherEmail: String, onComplete: (Boolean) -> Unit) {
        db.collection("teacher_group_requests").document(requestId).update("status", "accepted")
            .addOnSuccessListener {
                db.collection("groups").document(groupId)
                    .update("teachers", com.google.firebase.firestore.FieldValue.arrayUnion(teacherEmail))
                    .addOnSuccessListener { onComplete(true) }
                    .addOnFailureListener { onComplete(false) }
            }
            .addOnFailureListener { onComplete(false) }
    }

    /**
     * টিচার রিকোয়েস্ট রিজেক্ট করা
     */
    fun rejectTeacherRequest(requestId: String, onComplete: (Boolean) -> Unit) {
        db.collection("teacher_group_requests").document(requestId).update("status", "rejected")
            .addOnSuccessListener { onComplete(true) }
            .addOnFailureListener { onComplete(false) }
    }

    fun uploadFileFree(context: android.content.Context, groupId: String, senderEmail: String, fileUri: Uri, fileName: String, fileType: String, onComplete: (Boolean) -> Unit) {
        val client = okhttp3.OkHttpClient()
        try {
            val inputStream = context.contentResolver.openInputStream(fileUri)
            val fileBytes = inputStream?.readBytes() ?: throw Exception("File read failed")
            inputStream.close()
            val requestBody = okhttp3.MultipartBody.Builder()
                .setType(okhttp3.MultipartBody.FORM)
                .addFormDataPart("reqtype", "fileupload")
                .addFormDataPart("fileToUpload", fileName, fileBytes.toRequestBody(fileType.toMediaTypeOrNull()))
                .build()
            val request = okhttp3.Request.Builder().url("https://catbox.moe/user/api.php").post(requestBody).build()
            client.newCall(request).enqueue(object : okhttp3.Callback {
                override fun onFailure(call: okhttp3.Call, e: java.io.IOException) { onComplete(false) }
                override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                    val url = response.body?.string() ?: ""
                    if (url.startsWith("http")) {
                        saveMessage(groupId, senderEmail, "Shared a file", url, fileType, fileName)
                        onComplete(true)
                    } else { onComplete(false) }
                }
            })
        } catch (e: Exception) { onComplete(false) }
    }

    fun uploadFileToFirebase(groupId: String, senderEmail: String, fileUri: Uri, fileName: String, fileType: String, onComplete: (Boolean) -> Unit) {
        val storageRef = storage.reference.child("groups/$groupId/shared_files/${System.currentTimeMillis()}_$fileName")
        val metadata = com.google.firebase.storage.StorageMetadata.Builder().setContentType(fileType).build()
        storageRef.putFile(fileUri, metadata)
            .addOnSuccessListener {
                storageRef.downloadUrl.addOnSuccessListener { downloadUri ->
                    saveMessage(groupId, senderEmail, "Shared a file", downloadUri.toString(), fileType, fileName)
                    onComplete(true)
                }.addOnFailureListener { onComplete(false) }
            }
            .addOnFailureListener { onComplete(false) }
    }
}

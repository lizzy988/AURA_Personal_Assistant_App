<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

require_once "db.php";

function respond($success, $message, $data = null) {
    echo json_encode([
        "success" => $success,
        "message" => $message,
        "data" => $data
    ]);
    exit;
}

function validDateTime($date) {
    $d = DateTime::createFromFormat("Y-m-d H:i:s", $date);
    return $d && $d->format("Y-m-d H:i:s") === $date;
}

try {
    $input = json_decode(file_get_contents("php://input"), true);

    if (!is_array($input)) {
        respond(false, "Invalid request data.");
    }

    $action = $input["action"] ?? "";
    $userId = filter_var(
        $input["user_id"] ?? null,
        FILTER_VALIDATE_INT
    );

    if (!$userId) {
        respond(false, "Valid user ID is required.");
    }

    // Check that a linked task belongs to this user.
    function validateTask($conn, $taskId, $userId) {
        if ($taskId === null || $taskId === "") {
            return null;
        }

        $taskId = filter_var($taskId, FILTER_VALIDATE_INT);

        if (!$taskId) {
            throw new Exception("Invalid task ID.");
        }

        $stmt = $conn->prepare(
            "SELECT task_id FROM tasks
             WHERE task_id = ? AND user_id = ?"
        );
        $stmt->execute([$taskId, $userId]);

        if (!$stmt->fetch()) {
            throw new Exception("The selected task was not found.");
        }

        return $taskId;
    }

    // LIST REMINDERS
    if ($action === "list") {

        $stmt = $conn->prepare(
            "SELECT
                reminder_id,
                user_id,
                task_id,
                title,
                reminder_datetime,
                notification_sent,
                notification_enabled,
                status,
                CASE
                    WHEN status = 'Pending'
                    AND reminder_datetime < NOW()
                    THEN 1
                    ELSE 0
                END AS is_overdue
             FROM reminders
             WHERE user_id = ?
             ORDER BY reminder_datetime ASC"
        );

        $stmt->execute([$userId]);
        $reminders = $stmt->fetchAll();

        respond(true, "Reminders retrieved successfully.", $reminders);
    }

    // CREATE REMINDER
    elseif ($action === "create") {

        $title = trim($input["title"] ?? "");
        $dateTime = trim($input["reminder_datetime"] ?? "");

        if ($title === "" || strlen($title) > 150) {
            respond(false, "Enter a valid reminder title.");
        }

        if (!validDateTime($dateTime)) {
            respond(false, "Invalid reminder date and time.");
        }

        $taskId = validateTask(
            $conn,
            $input["task_id"] ?? null,
            $userId
        );

        $notificationEnabled = isset($input["notification_enabled"])
            ? (int)$input["notification_enabled"]
            : 1;

        if (!in_array($notificationEnabled, [0, 1], true)) {
            respond(false, "Invalid notification setting.");
        }

        $stmt = $conn->prepare(
            "INSERT INTO reminders
            (user_id, task_id, title, reminder_datetime,
             notification_sent, notification_enabled, status)
            VALUES (?, ?, ?, ?, 0, ?, 'Pending')"
        );

        $stmt->execute([
            $userId,
            $taskId,
            $title,
            $dateTime,
            $notificationEnabled
        ]);

        respond(true, "Reminder created successfully.");
    }

    // UPDATE REMINDER
    elseif ($action === "update") {

        $reminderId = filter_var(
            $input["reminder_id"] ?? null,
            FILTER_VALIDATE_INT
        );

        $title = trim($input["title"] ?? "");
        $dateTime = trim($input["reminder_datetime"] ?? "");

        if (!$reminderId) {
            respond(false, "Valid reminder ID is required.");
        }

        if ($title === "" || strlen($title) > 150) {
            respond(false, "Enter a valid reminder title.");
        }

        if (!validDateTime($dateTime)) {
            respond(false, "Invalid reminder date and time.");
        }

        $taskId = validateTask(
            $conn,
            $input["task_id"] ?? null,
            $userId
        );

        $notificationEnabled = isset($input["notification_enabled"])
            ? (int)$input["notification_enabled"]
            : 1;

        if (!in_array($notificationEnabled, [0, 1], true)) {
            respond(false, "Invalid notification setting.");
        }

        $stmt = $conn->prepare(
            "UPDATE reminders
             SET title = ?,
                 task_id = ?,
                 reminder_datetime = ?,
                 notification_enabled = ?,
                 notification_sent = 0
             WHERE reminder_id = ? AND user_id = ?"
        );

        $stmt->execute([
            $title,
            $taskId,
            $dateTime,
            $notificationEnabled,
            $reminderId,
            $userId
        ]);

        respond(true, "Reminder updated successfully.");
    }

    // COMPLETE REMINDER
    elseif ($action === "complete") {

        $reminderId = filter_var(
            $input["reminder_id"] ?? null,
            FILTER_VALIDATE_INT
        );

        if (!$reminderId) {
            respond(false, "Valid reminder ID is required.");
        }

        $stmt = $conn->prepare(
            "UPDATE reminders
             SET status = 'Completed'
             WHERE reminder_id = ? AND user_id = ?"
        );

        $stmt->execute([$reminderId, $userId]);

        respond(true, "Reminder marked as completed.");
    }

    // DELETE REMINDER
    elseif ($action === "delete") {

        $reminderId = filter_var(
            $input["reminder_id"] ?? null,
            FILTER_VALIDATE_INT
        );

        if (!$reminderId) {
            respond(false, "Valid reminder ID is required.");
        }

        $stmt = $conn->prepare(
            "DELETE FROM reminders
             WHERE reminder_id = ? AND user_id = ?"
        );

        $stmt->execute([$reminderId, $userId]);

        respond(true, "Reminder deleted successfully.");
    }

    else {
        respond(false, "Invalid action.");
    }

} catch (PDOException $e) {
    http_response_code(500);
    respond(false, "A database error occurred.");
} catch (Exception $e) {
    respond(false, $e->getMessage());
}
?>


<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

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

try {
    $input = json_decode(file_get_contents("php://input"), true);

    if (!is_array($input)) {
        respond(false, "Invalid request data.");
    }

    $action = $input["action"] ?? "";
    $userId = filter_var($input["user_id"] ?? null, FILTER_VALIDATE_INT);

    if (!$userId || $userId < 1) {
        respond(false, "A valid user ID is required.");
    }

    // LOAD ACTIVITIES
    if ($action === "list") {
        $sql = "
            SELECT
                task_id AS id,
                'Task' AS type,
                title,
                due_date AS scheduled_at,
                priority,
                IF(status = 'Completed', 1, 0) AS completed
            FROM tasks
            WHERE user_id = :task_user

            UNION ALL

            SELECT
                schedule_id AS id,
                'Appointment' AS type,
                title,
                start_time AS scheduled_at,
                priority,
                IF(status = 'Completed', 1, 0) AS completed
            FROM schedules
            WHERE user_id = :schedule_user

            ORDER BY scheduled_at ASC
        ";

        $stmt = $conn->prepare($sql);
        $stmt->execute([
            "task_user" => $userId,
            "schedule_user" => $userId
        ]);

        respond(true, "Activities loaded.", $stmt->fetchAll());
    }

    // ADD ACTIVITY
    if ($action === "create") {
        $title = trim($input["title"] ?? "");
        $type = $input["type"] ?? "Task";
        $scheduledAt = $input["scheduled_at"] ?? "";
        $priority = $input["priority"] ?? "Medium";

        if ($title === "" || strlen($title) > 150) {
            respond(false, "Enter a title of up to 150 characters.");
        }

        if (!in_array($type, ["Task", "Appointment"], true)) {
            respond(false, "Invalid activity type.");
        }

        if (!in_array($priority, ["Low", "Medium", "High"], true)) {
            respond(false, "Invalid priority.");
        }

        $date = DateTime::createFromFormat("Y-m-d H:i:s", $scheduledAt);

        if (!$date) {
            respond(false, "Invalid activity date or time.");
        }

        if ($type === "Task") {
            $stmt = $conn->prepare("
                INSERT INTO tasks
                    (user_id, title, due_date, priority, status)
                VALUES
                    (:user_id, :title, :due_date, :priority, 'Pending')
            ");

            $stmt->execute([
                "user_id" => $userId,
                "title" => $title,
                "due_date" => $date->format("Y-m-d H:i:s"),
                "priority" => $priority
            ]);

            $newId = (int)$conn->lastInsertId();

        } else {
            $endDate = clone $date;
            $endDate->modify("+1 hour");

            $stmt = $conn->prepare("
                INSERT INTO schedules
                    (user_id, title, start_time, end_time, priority, status)
                VALUES
                    (:user_id, :title, :start_time, :end_time, :priority, 'Pending')
            ");

            $stmt->execute([
                "user_id" => $userId,
                "title" => $title,
                "start_time" => $date->format("Y-m-d H:i:s"),
                "end_time" => $endDate->format("Y-m-d H:i:s"),
                "priority" => $priority
            ]);

            $newId = (int)$conn->lastInsertId();
        }

        respond(true, "Activity added successfully.", ["id" => $newId]);
    }

    // UPDATE ACTIVITY
    if ($action === "update") {
        $id = filter_var($input["id"] ?? null, FILTER_VALIDATE_INT);
        $type = $input["type"] ?? "";
        $title = trim($input["title"] ?? "");
        $scheduledAt = $input["scheduled_at"] ?? "";
        $priority = $input["priority"] ?? "Medium";
        $completed = !empty($input["completed"]);

        if (!$id || $id < 1 || $title === "" || strlen($title) > 150) {
            respond(false, "Invalid activity details.");
        }

        if (!in_array($type, ["Task", "Appointment"], true) ||
            !in_array($priority, ["Low", "Medium", "High"], true)) {
            respond(false, "Invalid activity type or priority.");
        }

        $date = DateTime::createFromFormat("Y-m-d H:i:s", $scheduledAt);

        if (!$date) {
            respond(false, "Invalid activity date or time.");
        }

        if ($type === "Task") {
            $stmt = $conn->prepare("
                UPDATE tasks
                SET title = :title,
                    due_date = :due_date,
                    priority = :priority,
                    status = :status
                WHERE task_id = :id AND user_id = :user_id
            ");

            $stmt->execute([
                "title" => $title,
                "due_date" => $date->format("Y-m-d H:i:s"),
                "priority" => $priority,
                "status" => $completed ? "Completed" : "Pending",
                "id" => $id,
                "user_id" => $userId
            ]);

        } else {
            $endDate = clone $date;
            $endDate->modify("+1 hour");

            $stmt = $conn->prepare("
                UPDATE schedules
                SET title = :title,
                    start_time = :start_time,
                    end_time = :end_time,
                    priority = :priority,
                    status = :status
                WHERE schedule_id = :id AND user_id = :user_id
            ");

            $stmt->execute([
                "title" => $title,
                "start_time" => $date->format("Y-m-d H:i:s"),
                "end_time" => $endDate->format("Y-m-d H:i:s"),
                "priority" => $priority,
                "status" => $completed ? "Completed" : "Pending",
                "id" => $id,
                "user_id" => $userId
            ]);
        }

        respond(true, "Activity updated successfully.");
    }

    // DELETE ACTIVITY
    if ($action === "delete") {
        $id = filter_var($input["id"] ?? null, FILTER_VALIDATE_INT);
        $type = $input["type"] ?? "";

        if (!$id || $id < 1 || !in_array($type, ["Task", "Appointment"], true)) {
            respond(false, "Invalid activity details.");
        }

        if ($type === "Task") {
            $stmt = $conn->prepare("
                DELETE FROM tasks
                WHERE task_id = :id AND user_id = :user_id
            ");
        } else {
            $stmt = $conn->prepare("
                DELETE FROM schedules
                WHERE schedule_id = :id AND user_id = :user_id
            ");
        }

        $stmt->execute([
            "id" => $id,
            "user_id" => $userId
        ]);

        respond(true, "Activity deleted successfully.");
    }

    respond(false, "Unknown action.");

} catch (PDOException $e) {
    http_response_code(500);
    respond(false, "A database error occurred.");
} catch (Exception $e) {
    http_response_code(500);
    respond(false, "Something went wrong.");
}
?>

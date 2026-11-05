
<?php

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER["REQUEST_METHOD"] === "OPTIONS") {
    http_response_code(200);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Only POST requests are allowed."
    ]);
    exit;
}

require_once "db.php";

$data = json_decode(file_get_contents("php://input"), true);

$fullName = trim($data["full_name"] ?? "");
$email = trim($data["email"] ?? "");
$password = $data["password"] ?? "";

if ($fullName === "" || $email === "" || $password === "") {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Please provide your full name, email and password."
    ]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Please enter a valid email address."
    ]);
    exit;
}

if (strlen($password) < 8) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Password must contain at least 8 characters."
    ]);
    exit;
}

try {
    $check = $conn->prepare(
        "SELECT user_id FROM users WHERE email = ?"
    );
    $check->execute([$email]);

    if ($check->fetch()) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "An account with this email already exists."
        ]);
        exit;
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $stmt = $conn->prepare(
        "INSERT INTO users (full_name, email, password)
         VALUES (?, ?, ?)"
    );

    $stmt->execute([
        $fullName,
        $email,
        $hashedPassword
    ]);

    http_response_code(201);
    echo json_encode([
        "success" => true,
        "message" => "Account created successfully!"
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Unable to create account. Please try again."
    ]);
}

?>

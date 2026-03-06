CREATE TABLE users (
    id_user SERIAL PRIMARY KEY,
    user_name VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    pass TEXT NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'Usuario',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    profile_image TEXT
);

CREATE TABLE ai_analysis (
    id_analysis SERIAL PRIMARY KEY,
    id_user INTEGER REFERENCES users(id_user) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    markdown_content TEXT,
    bpmn_xml TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar a Juan (Admin)
INSERT INTO users (user_name, email, pass, rol)
VALUES ('Admin123', 'admin@gmail.com', '$2b$10$oJz0gSqtHhV6BSOy5frX/u5qknSC6XlJZ/gTQRGuROACkIUD5WPEe', 'Admin');

-- Insertar a Max (Usuario)
INSERT INTO users (user_name, email, pass, rol)
VALUES ('Usuario123', 'usuario@gmail.com', '$2b$10$pNVq12sxmyggDyoG9Tc4oeRYMMRm2tROm7lRkiF3OiBV6YEW2Aly2', 'Usuario');

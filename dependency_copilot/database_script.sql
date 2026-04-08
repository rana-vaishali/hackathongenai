CREATE USER dep_user WITH PASSWORD 'DepCopilot@123';

GRANT ALL PRIVILEGES ON DATABASE dependency_copilot TO dep_user;
GRANT USAGE, CREATE ON SCHEMA public TO dep_user;

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    owner TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    title TEXT NOT NULL,
    owner TEXT,
    status TEXT DEFAULT 'open',
    priority TEXT DEFAULT 'medium',
    due_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE task_dependencies (
    id SERIAL PRIMARY KEY,
    task_id INT REFERENCES tasks(id),
    depends_on_task_id INT REFERENCES tasks(id),
    dependency_type TEXT DEFAULT 'blocks'
);

CREATE TABLE blocker_notes (
    id SERIAL PRIMARY KEY,
    task_id INT REFERENCES tasks(id),
    note TEXT NOT NULL,
    severity TEXT DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE followups (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    title TEXT NOT NULL,
    scheduled_at TIMESTAMP NOT NULL,
    status TEXT DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE action_summaries (
    id SERIAL PRIMARY KEY,
    project_id INT REFERENCES projects(id),
    summary TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO projects (id, name, owner, status) VALUES
(1, 'Website Redesign Sprint', 'Nina', 'active');

INSERT INTO tasks (id, project_id, title, owner, status, priority, due_date) VALUES
(1, 1, 'Finalize design review', 'Asha', 'open', 'high', '2026-04-08 12:00:00'),
(2, 1, 'Approve homepage layout', 'Rahul', 'open', 'high', '2026-04-08 18:00:00'),
(3, 1, 'Start frontend implementation', 'David', 'open', 'high', '2026-04-09 10:00:00'),
(4, 1, 'QA landing page flow', 'Lebo', 'open', 'medium', '2026-04-10 15:00:00'),
(5, 1, 'Client demo sign-off', 'Nina', 'open', 'high', '2026-04-11 11:00:00');

INSERT INTO task_dependencies (task_id, depends_on_task_id, dependency_type) VALUES
(2, 1, 'blocks'),
(3, 2, 'blocks'),
(4, 3, 'blocks'),
(5, 4, 'blocks');

INSERT INTO blocker_notes (task_id, note, severity) VALUES
(1, 'Design team is waiting for final brand color confirmation.', 'high'),
(2, 'Homepage layout approval cannot proceed until design review is closed.', 'high');

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO dep_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dep_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dep_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO dep_user;
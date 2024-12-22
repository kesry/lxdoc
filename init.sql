CREATE TABLE IF NOT EXISTS sys_user_info
(
    id        integer PRIMARY KEY AUTOINCREMENT,
    user_name varchar(64)           DEFAULT NULL,
    account   varchar(32)  NOT NULL ,
    password  varchar(256) NOT NULL,
    avatar    varchar(1024)         DEFAULT NULL,
    create_at DATETIME     NOT NULL ,
    version   int NOT NULL DEFAULT ,
    update_at DATETIME     NOT NULL ,
    status    int          NOT NULL DEFAULT 
);

CREATE TABLE IF NOT EXISTS sys_attachment
(
    id         integer PRIMARY KEY AUTOINCREMENT,
    name       varchar(256)          DEFAULT NULL,
    path       varchar(512) NOT NULL,
    remark     varchar(512)          DEFAULT NULL,
    size       integer NOT NULL DEFAULT ,
    version    int NOT NULL DEFAULT 0,
    creator_id integer NOT NULL ,
    create_at  DATETIME     NOT NULL,
    update_at  DATETIME     NOT NULL,
    status     int          NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sys_user_config
(
    id             integer PRIMARY KEY AUTOINCREMENT,
    config_type    varchar(32) NOT NULL ,
    config_content varchar(1024)        DEFAULT NULL ,
    version        int NOT NULL DEFAULT 0,
    user_id        integer NOT NULL ,
    create_at      DATETIME    NOT NULL ,
    update_at      DATETIME    NOT NULL,
    status         int         NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS doc_file_folder
(
    id           integer PRIMARY KEY AUTOINCREMENT,
    parent_id   integer NOT NULl,
    name         varchar(128) NOT NULL,
    file_count   int NOT NULL DEFAULT 0 ,
    folder_count int NOT NULL DEFAULT 0,
    format       int NOT NULL ,
    file_type    varchar(32) NOT NULL,
    collected    int NOT NULL,
    img          varchar(1024) DEFAULT NULL,
    version      int NOT NULL DEFAULT 0 ,
    creator_id   integer NOT NULL ,
    create_at    datetime    NOT NULL,
    update_at    datetime    NOT NULL ,
    status       int NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS doc_file_content
(
    id         integer PRIMARY KEY AUTOINCREMENT,
    content    text ,
    version    int NOT NULL DEFAULT 0,
    creator_id integer NOT NULL ,
    create_at  datetime NOT NULL,
    update_at  datetime NOT NULL ,
);

CREATE TABLE IF NOT EXISTS doc_collect_folder
(
    id        integer PRIMARY KEY AUTOINCREMENT,
    name      varchar(128) NOT NULL,
    user_id   integer NOT NULL,
    create_at DATETIME    NOT NULL,
    status    int         NOT NULL DEFAULT 
);

CREATE TABLE IF NOT EXISTS doc_recycle
(
    id        integer PRIMARY KEY AUTOINCREMENT,
    ids varchar(1020) NOT NULL,
    name      varchar(128) NOT NULL,
    user_id   integer NOT NULL,
    create_at DATETIME    NOT NULL
);
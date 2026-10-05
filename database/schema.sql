-- Schéma MySQL / MariaDB — Application de gestion de garage personnel
-- Charset utf8mb4 partout, InnoDB pour les FK.

SET NAMES utf8mb4;

-- =========================================================
-- Table: vehicle_categories
-- Catégories de véhicules (liste de référence extensible)
-- =========================================================
CREATE TABLE vehicle_categories (
    id      INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50)     NOT NULL UNIQUE,
    is_default  TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Une seule catégorie par défaut'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO vehicle_categories (name, is_default) VALUES ('Moto', 0), ('Voiture', 0), ('Autre', 1);

-- =========================================================
-- Table: vehicles
-- =========================================================
CREATE TABLE vehicles (
    id                          CHAR(36)        NOT NULL PRIMARY KEY,
    custom_name                 VARCHAR(100)    NOT NULL,
    vehicle_category_id         INT UNSIGNED    NOT NULL,
    status                      ENUM('current','historical')   NOT NULL DEFAULT 'current',

    brand                       VARCHAR(100)    NOT NULL,
    model                       VARCHAR(100)    NOT NULL,
    license_plate               VARCHAR(20)     NULL,
    vin                         VARCHAR(50)     NULL,
    first_registration_date     DATE            NULL,

    energy                      ENUM('essence','diesel','electrique','hybride','gpl','autre') NULL,
    fiscal_power                 SMALLINT UNSIGNED NULL COMMENT 'Puissance fiscale (CV)',
    power_hp                    SMALLINT UNSIGNED NULL COMMENT 'Puissance en chevaux DIN (CH)',
    weight_kg                   SMALLINT UNSIGNED NULL COMMENT 'Poids (kg)',
    color                       VARCHAR(50)     NULL,

    mileage                     INT UNSIGNED    NOT NULL DEFAULT 0,
    comment                     TEXT            NULL,
    photo_filename               VARCHAR(255)    NULL,
    is_favorite                 TINYINT(1)      NOT NULL DEFAULT 0 COMMENT 'Affiché sur l''accueil',

    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_vehicles_category
        FOREIGN KEY (vehicle_category_id) REFERENCES vehicle_categories(id) ON DELETE RESTRICT,

    INDEX idx_vehicles_category_status (vehicle_category_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
CREATE TABLE vehicle_vehicle_categories (
    vehicle_id              CHAR(36)        NOT NULL,
    vehicle_category_id     INT UNSIGNED    NOT NULL,

    PRIMARY KEY (vehicle_id, vehicle_category_id),
    CONSTRAINT fk_vehicle_categories_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_vehicle_categories_category
        FOREIGN KEY (vehicle_category_id) REFERENCES vehicle_categories(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: maintenance_types
-- Types d'entretien (liste extensible, pré-remplie + perso)
-- =========================================================
CREATE TABLE maintenance_types (
    id          INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(50)     NOT NULL UNIQUE,
    label       VARCHAR(100)    NOT NULL,
    icon        VARCHAR(50)     NULL,
    is_custom   TINYINT(1)      NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO maintenance_types (code, label, icon, is_custom) VALUES
    ('vidange',                'Vidange',                          'oil_barrel',  0),
    ('pneus',                  'Changement de pneus',              'tire_repair', 0),
    ('plaquettes',             'Plaquettes de frein',              'disc_full',   0),
    ('distribution',           'Distribution',                     'settings',    0),
    ('controle_technique',     'Contrôle technique',               'fact_check',  0),
    ('revision',               'Révision',                         'build',       0),
    ('petit_entretien',        'Petit entretien (nettoyage/chaîne)', 'cleaning_services', 0),
    ('entretien_personnalise', 'Entretien personnalisé',           'edit_note',   0);

-- =========================================================
-- Table: addresses
-- Adresses postales (utilisées par les organisations)
-- =========================================================
CREATE TABLE addresses (
    id              CHAR(36)        NOT NULL PRIMARY KEY,
    street          VARCHAR(255)    NOT NULL,
    complement      VARCHAR(255)    NULL,
    postal_code     VARCHAR(10)     NOT NULL,
    city            VARCHAR(100)    NOT NULL,
    region          VARCHAR(100)    NULL,
    country         VARCHAR(100)    NOT NULL DEFAULT 'France',
    latitude        DECIMAL(10,7)   NULL,
    longitude       DECIMAL(10,7)   NULL,

    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: organization_types
-- Types d'organisation (liste de référence extensible)
-- =========================================================
CREATE TABLE organization_types (
    id      INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(100)    NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO organization_types (name) VALUES
    ('Garage'), ('Concessionnaire'), ('Contrôle technique'), ('Assurance'), ('Autre');

-- =========================================================
-- Table: organizations
-- Garages / intervenants ("Mes garages"). `is_mine` désigne
-- l'entrée "Moi-même" pour les entretiens réalisés soi-même.
-- =========================================================
CREATE TABLE organizations (
    id              CHAR(36)        NOT NULL PRIMARY KEY,
    name            VARCHAR(150)    NOT NULL,
    organization_type_id INT UNSIGNED NULL COMMENT 'NULL autorisé si is_mine',
    phone           VARCHAR(30)     NULL,
    mobile          VARCHAR(30)     NULL,
    website         VARCHAR(255)    NULL,
    address_id      CHAR(36)        NULL,
    comment         TEXT            NULL,
    is_archived     TINYINT(1)      NOT NULL DEFAULT 0,
    is_mine         TINYINT(1)      NOT NULL DEFAULT 0,

    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_organizations_type
        FOREIGN KEY (organization_type_id) REFERENCES organization_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_organizations_address
        FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: organization_vehicle_categories (N-N)
-- Catégories de véhicules prises en charge par une organisation
-- =========================================================
CREATE TABLE organization_vehicle_categories (
    organization_id         CHAR(36)        NOT NULL,
    vehicle_category_id     INT UNSIGNED    NOT NULL,

    PRIMARY KEY (organization_id, vehicle_category_id),
    CONSTRAINT fk_org_categories_organization
        FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    CONSTRAINT fk_org_categories_category
        FOREIGN KEY (vehicle_category_id) REFERENCES vehicle_categories(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: maintenances
-- Historique des interventions réalisées
-- =========================================================
CREATE TABLE maintenances (
    id                    CHAR(36)        NOT NULL PRIMARY KEY,
    vehicle_id            CHAR(36)        NOT NULL,
    maintenance_type_id   INT UNSIGNED    NOT NULL,

    date                  DATE            NOT NULL,
    mileage               INT UNSIGNED    NULL,
    description           TEXT            NULL,
    cost                  DECIMAL(10,2)   NULL,
    organization_id       CHAR(36)        NOT NULL COMMENT 'Garage / intervenant',
    comment               TEXT            NULL,

    created_at            TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_maintenances_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenances_type
        FOREIGN KEY (maintenance_type_id) REFERENCES maintenance_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_maintenances_organization
        FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE RESTRICT,

    INDEX idx_maintenances_vehicle_date (vehicle_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: maintenance_schedules
-- Prochaines échéances d'entretien (par date et/ou km)
-- =========================================================
CREATE TABLE maintenance_schedules (
    id                     CHAR(36)        NOT NULL PRIMARY KEY,
    vehicle_id             CHAR(36)        NOT NULL,
    maintenance_type_id    INT UNSIGNED    NOT NULL,

    due_date               DATE            NULL,
    due_mileage            INT UNSIGNED    NULL,
    last_maintenance_id    CHAR(36)        NULL COMMENT 'Référence à la dernière intervention de ce type',
    comment                TEXT            NULL,
    interval_months        INT UNSIGNED    NULL COMMENT 'Intervalle saisi en mode « dans », repris à la replanification',
    interval_mileage       INT UNSIGNED    NULL COMMENT 'Intervalle saisi en mode « dans », repris à la replanification',

    created_at             TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_schedules_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_schedules_type
        FOREIGN KEY (maintenance_type_id) REFERENCES maintenance_types(id) ON DELETE RESTRICT,
    CONSTRAINT fk_schedules_last_maintenance
        FOREIGN KEY (last_maintenance_id) REFERENCES maintenances(id) ON DELETE SET NULL,

    INDEX idx_schedules_vehicle (vehicle_id),
    INDEX idx_schedules_due_date (due_date),
    INDEX idx_schedules_due_mileage (due_mileage)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Table: documents
-- Documents liés à un véhicule (et éventuellement à un entretien)
-- =========================================================
CREATE TABLE documents (
    id              CHAR(36)        NOT NULL PRIMARY KEY,
    vehicle_id      CHAR(36)        NOT NULL,
    maintenance_id  CHAR(36)        NULL,

    type            ENUM('carte_grise','assurance','controle_technique','facture','entretien','autre') NOT NULL,
    filename        VARCHAR(255)    NOT NULL COMMENT 'Nom du fichier uploadé',
    comment         VARCHAR(255)    NULL,

    uploaded_at     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_documents_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    CONSTRAINT fk_documents_maintenance
        FOREIGN KEY (maintenance_id) REFERENCES maintenances(id) ON DELETE SET NULL,

    INDEX idx_documents_vehicle (vehicle_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

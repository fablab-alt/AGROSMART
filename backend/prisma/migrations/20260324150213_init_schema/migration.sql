-- CreateTable
CREATE TABLE `regions` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `code` VARCHAR(10) NOT NULL,
    `chef_lieu` VARCHAR(100) NULL,
    `superficie_km2` DECIMAL(10, 2) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `regions_nom_key`(`nom`),
    UNIQUE INDEX `regions_code_key`(`code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `cooperatives` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(200) NOT NULL,
    `code` VARCHAR(20) NOT NULL,
    `region_id` VARCHAR(191) NULL,
    `adresse` TEXT NULL,
    `telephone` VARCHAR(20) NULL,
    `email` VARCHAR(100) NULL,
    `nombre_membres` INTEGER NOT NULL DEFAULT 0,
    `date_creation` DATE NULL,
    `est_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `cooperatives_code_key`(`code`),
    INDEX `cooperatives_region_id_idx`(`region_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `users` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `prenoms` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) NULL,
    `telephone` VARCHAR(20) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('ADMIN', 'AGRONOME', 'PRODUCTEUR', 'ACHETEUR', 'FOURNISSEUR', 'CONSEILLER', 'PARTENAIRE') NOT NULL DEFAULT 'PRODUCTEUR',
    `statut` ENUM('ACTIF', 'INACTIF', 'SUSPENDU', 'EN_ATTENTE') NOT NULL DEFAULT 'EN_ATTENTE',
    `region_id` VARCHAR(191) NULL,
    `photo_profil` TEXT NULL,
    `date_naissance` DATE NULL,
    `adresse` TEXT NULL,
    `preferences_notification` JSON NULL,
    `whatsapp_verifie` BOOLEAN NOT NULL DEFAULT false,
    `email_verifie` BOOLEAN NOT NULL DEFAULT false,
    `derniere_connexion` DATETIME(3) NULL,
    `langue_preferee` VARCHAR(10) NOT NULL DEFAULT 'fr',
    `points` INTEGER NOT NULL DEFAULT 0,
    `niveau` VARCHAR(50) NOT NULL DEFAULT 'Novice',
    `badge` VARCHAR(100) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `deleted_by` VARCHAR(100) NULL,
    `production_3_mois_precedents_kg` DECIMAL(10, 2) NULL,
    `production_mois1_kg` DECIMAL(10, 2) NULL,
    `production_mois2_kg` DECIMAL(10, 2) NULL,
    `production_mois3_kg` DECIMAL(10, 2) NULL,
    `type_producteur` VARCHAR(100) NULL,
    `superficie_exploitee` DECIMAL(10, 2) NULL,
    `unite_superficie` VARCHAR(10) NULL,
    `systeme_irrigation` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `users_email_key`(`email`),
    UNIQUE INDEX `users_telephone_key`(`telephone`),
    INDEX `users_email_idx`(`email`),
    INDEX `users_telephone_idx`(`telephone`),
    INDEX `users_region_id_idx`(`region_id`),
    INDEX `users_role_statut_idx`(`role`, `statut`),
    INDEX `users_is_active_idx`(`is_active`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `password_history` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `password_history_user_id_idx`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `otp_codes` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `code` VARCHAR(10) NOT NULL,
    `type` ENUM('LOGIN', 'REGISTER', 'RESET') NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `used` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `otp_codes_user_id_type_used_idx`(`user_id`, `type`, `used`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `parcelles` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(200) NOT NULL,
    `superficie` DECIMAL(10, 2) NOT NULL,
    `type_sol` VARCHAR(50) NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `region_id` VARCHAR(191) NULL,
    `culture_actuelle` VARCHAR(100) NULL,
    `date_plantation` DATE NULL,
    `statut` ENUM('ACTIVE', 'EN_REPOS', 'PREPAREE', 'ENSEMENCEE', 'EN_CROISSANCE', 'RECOLTE') NOT NULL DEFAULT 'ACTIVE',
    `sante` ENUM('OPTIMAL', 'SURVEILLANCE', 'CRITIQUE') NOT NULL DEFAULT 'OPTIMAL',
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `parcelles_user_id_idx`(`user_id`),
    INDEX `parcelles_region_id_idx`(`region_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stations` (
    `id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(200) NOT NULL,
    `code` VARCHAR(100) NULL,
    `modele` VARCHAR(100) NULL,
    `numero_serie` VARCHAR(100) NULL,
    `statut` ENUM('ACTIVE', 'MAINTENANCE', 'HORS_SERVICE') NOT NULL DEFAULT 'ACTIVE',
    `batterie` INTEGER NULL,
    `signal` INTEGER NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `derniere_connexion` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `stations_code_key`(`code`),
    UNIQUE INDEX `stations_numero_serie_key`(`numero_serie`),
    INDEX `stations_parcelle_id_idx`(`parcelle_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `capteurs` (
    `id` VARCHAR(191) NOT NULL,
    `station_id` VARCHAR(191) NULL,
    `parcelle_id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(200) NOT NULL,
    `type` ENUM('HUMIDITE_TEMPERATURE_AMBIANTE', 'HUMIDITE_SOL', 'UV', 'NPK', 'DIRECTION_VENT', 'TRANSPIRATION_PLANTE') NOT NULL,
    `unite` VARCHAR(20) NOT NULL,
    `seuil_min` DECIMAL(10, 2) NOT NULL,
    `seuil_max` DECIMAL(10, 2) NOT NULL,
    `statut` ENUM('ACTIF', 'INACTIF', 'MAINTENANCE', 'DEFAILLANT') NOT NULL DEFAULT 'ACTIF',
    `signal` INTEGER NULL,
    `batterie` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `capteurs_station_id_idx`(`station_id`),
    INDEX `capteurs_parcelle_id_idx`(`parcelle_id`),
    INDEX `capteurs_type_idx`(`type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `mesures` (
    `id` VARCHAR(191) NOT NULL,
    `capteur_id` VARCHAR(191) NOT NULL,
    `valeur` DECIMAL(15, 4) NOT NULL,
    `unite` VARCHAR(20) NOT NULL,
    `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `mesures_capteur_id_timestamp_idx`(`capteur_id`, `timestamp`),
    INDEX `mesures_timestamp_idx`(`timestamp`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `alertes` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `capteur_id` VARCHAR(191) NULL,
    `type` VARCHAR(50) NOT NULL,
    `niveau` ENUM('INFO', 'IMPORTANT', 'CRITIQUE') NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `statut` ENUM('NOUVELLE', 'LUE', 'TRAITEE', 'IGNOREE') NOT NULL DEFAULT 'NOUVELLE',
    `donnees` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `alertes_user_id_statut_idx`(`user_id`, `statut`),
    INDEX `alertes_capteur_id_idx`(`capteur_id`),
    INDEX `alertes_created_at_idx`(`created_at`),
    INDEX `alertes_niveau_created_at_idx`(`niveau`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `diagnostics` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NULL,
    `type` VARCHAR(50) NOT NULL DEFAULT 'disease',
    `disease_name` VARCHAR(255) NULL,
    `crop_type` VARCHAR(100) NULL,
    `confidence_score` DECIMAL(5, 2) NULL,
    `severity` VARCHAR(50) NULL,
    `image_url` TEXT NULL,
    `recommendations` TEXT NULL,
    `treatment_suggestions` TEXT NULL,
    `resultat` JSON NULL,
    `parametres` JSON NULL,
    `modele_utilise` VARCHAR(100) NULL,
    `score_confiance` DECIMAL(5, 2) NULL,
    `localisation` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `diagnostics_user_id_idx`(`user_id`),
    INDEX `diagnostics_parcelle_id_idx`(`parcelle_id`),
    INDEX `diagnostics_user_id_created_at_idx`(`user_id`, `created_at`),
    INDEX `diagnostics_type_idx`(`type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `formations` (
    `id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `niveau` VARCHAR(50) NOT NULL,
    `duree_minutes` INTEGER NOT NULL,
    `image_url` TEXT NULL,
    `active` BOOLEAN NOT NULL DEFAULT true,
    `vues` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `modules_formation` (
    `id` VARCHAR(191) NOT NULL,
    `formation_id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `contenu` TEXT NOT NULL,
    `ordre` INTEGER NOT NULL,
    `video_url` TEXT NULL,
    `documents_url` TEXT NULL,
    `quiz_data` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `modules_formation_formation_id_idx`(`formation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `progressions_formation` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `formation_id` VARCHAR(191) NOT NULL,
    `progression` INTEGER NOT NULL DEFAULT 0,
    `complete` BOOLEAN NOT NULL DEFAULT false,
    `modules_termines` JSON NULL,
    `score` INTEGER NULL,
    `certificat_url` TEXT NULL,
    `date_debut` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `date_fin` DATETIME(3) NULL,

    INDEX `progressions_formation_user_id_idx`(`user_id`),
    INDEX `progressions_formation_formation_id_idx`(`formation_id`),
    UNIQUE INDEX `progressions_formation_user_id_formation_id_key`(`user_id`, `formation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `marketplace_produits` (
    `id` VARCHAR(191) NOT NULL,
    `vendeur_id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `prix` DECIMAL(12, 2) NOT NULL,
    `unite` VARCHAR(50) NOT NULL,
    `stock` INTEGER NOT NULL DEFAULT 0,
    `images` JSON NULL,
    `specifications` JSON NULL,
    `type_offre` VARCHAR(20) NOT NULL DEFAULT 'vente',
    `prix_location_jour` DECIMAL(12, 2) NULL,
    `duree_min_location` INTEGER NULL,
    `caution` DECIMAL(12, 2) NULL,
    `etat` VARCHAR(50) NULL DEFAULT 'bon',
    `actif` BOOLEAN NOT NULL DEFAULT true,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `marketplace_produits_vendeur_id_idx`(`vendeur_id`),
    INDEX `marketplace_produits_categorie_idx`(`categorie`),
    INDEX `marketplace_produits_actif_prix_idx`(`actif`, `prix`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `carts` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `carts_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `cart_items` (
    `id` VARCHAR(191) NOT NULL,
    `cart_id` VARCHAR(191) NOT NULL,
    `produit_id` VARCHAR(191) NOT NULL,
    `quantite` INTEGER NOT NULL DEFAULT 1,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `cart_items_cart_id_idx`(`cart_id`),
    INDEX `cart_items_produit_id_idx`(`produit_id`),
    UNIQUE INDEX `cart_items_cart_id_produit_id_key`(`cart_id`, `produit_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `favorites` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `produit_id` VARCHAR(191) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `favorites_user_id_idx`(`user_id`),
    INDEX `favorites_produit_id_idx`(`produit_id`),
    UNIQUE INDEX `favorites_user_id_produit_id_key`(`user_id`, `produit_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `wishlists` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `wishlists_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `wishlist_items` (
    `id` VARCHAR(191) NOT NULL,
    `wishlist_id` VARCHAR(191) NOT NULL,
    `produit_id` VARCHAR(191) NOT NULL,
    `added_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `wishlist_items_wishlist_id_idx`(`wishlist_id`),
    INDEX `wishlist_items_produit_id_idx`(`produit_id`),
    UNIQUE INDEX `wishlist_items_wishlist_id_produit_id_key`(`wishlist_id`, `produit_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `avis` (
    `id` VARCHAR(191) NOT NULL,
    `produit_id` VARCHAR(191) NOT NULL,
    `utilisateur_id` VARCHAR(191) NOT NULL,
    `note` INTEGER NOT NULL,
    `commentaire` TEXT NULL,
    `images` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `avis_produit_id_idx`(`produit_id`),
    INDEX `avis_utilisateur_id_idx`(`utilisateur_id`),
    INDEX `avis_note_idx`(`note`),
    UNIQUE INDEX `avis_produit_id_utilisateur_id_key`(`produit_id`, `utilisateur_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `marketplace_commandes` (
    `id` VARCHAR(191) NOT NULL,
    `acheteur_id` VARCHAR(191) NOT NULL,
    `vendeur_id` VARCHAR(191) NULL,
    `produit_id` VARCHAR(191) NOT NULL,
    `quantite` INTEGER NOT NULL,
    `prix_unitaire` DECIMAL(12, 2) NOT NULL,
    `prix_total` DECIMAL(12, 2) NOT NULL,
    `statut` ENUM('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    `date_debut` DATETIME(3) NULL,
    `date_fin` DATETIME(3) NULL,
    `statut_location` VARCHAR(50) NULL,
    `caution_versee` DECIMAL(12, 2) NULL,
    `statut_caution` VARCHAR(50) NULL,
    `adresse_livraison` TEXT NULL,
    `mode_livraison` VARCHAR(50) NULL,
    `notes` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `marketplace_commandes_acheteur_id_idx`(`acheteur_id`),
    INDEX `marketplace_commandes_produit_id_idx`(`produit_id`),
    INDEX `marketplace_commandes_statut_idx`(`statut`),
    INDEX `marketplace_commandes_vendeur_id_statut_idx`(`vendeur_id`, `statut`),
    INDEX `marketplace_commandes_acheteur_id_statut_idx`(`acheteur_id`, `statut`),
    INDEX `marketplace_commandes_created_at_idx`(`created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `marketplace_transactions` (
    `id` VARCHAR(191) NOT NULL,
    `commande_id` VARCHAR(191) NOT NULL,
    `montant` DECIMAL(12, 2) NOT NULL,
    `methode_paiement` VARCHAR(50) NULL,
    `statut` ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    `reference_transaction` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `marketplace_transactions_reference_transaction_key`(`reference_transaction`),
    INDEX `marketplace_transactions_commande_id_idx`(`commande_id`),
    INDEX `marketplace_transactions_statut_idx`(`statut`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `forum_posts` (
    `id` VARCHAR(191) NOT NULL,
    `auteur_id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `contenu` TEXT NOT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `vues` INTEGER NOT NULL DEFAULT 0,
    `resolu` BOOLEAN NOT NULL DEFAULT false,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `forum_posts_auteur_id_idx`(`auteur_id`),
    INDEX `forum_posts_categorie_idx`(`categorie`),
    INDEX `forum_posts_resolu_created_at_idx`(`resolu`, `created_at`),
    INDEX `forum_posts_created_at_idx`(`created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `forum_reponses` (
    `id` VARCHAR(191) NOT NULL,
    `post_id` VARCHAR(191) NOT NULL,
    `auteur_id` VARCHAR(191) NOT NULL,
    `contenu` TEXT NOT NULL,
    `est_solution` BOOLEAN NOT NULL DEFAULT false,
    `upvotes` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `forum_reponses_post_id_idx`(`post_id`),
    INDEX `forum_reponses_auteur_id_idx`(`auteur_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `messages` (
    `id` VARCHAR(191) NOT NULL,
    `conversation_id` VARCHAR(191) NULL,
    `expediteur_id` VARCHAR(191) NOT NULL,
    `destinataire_id` VARCHAR(191) NOT NULL,
    `sujet` VARCHAR(255) NULL,
    `contenu` TEXT NOT NULL,
    `lu` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `messages_conversation_id_created_at_idx`(`conversation_id`, `created_at`),
    INDEX `messages_expediteur_id_idx`(`expediteur_id`),
    INDEX `messages_destinataire_id_lu_idx`(`destinataire_id`, `lu`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `cultures` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `nom_scientifique` VARCHAR(150) NULL,
    `categorie` ENUM('CEREALES', 'LEGUMINEUSES', 'TUBERCULES', 'LEGUMES', 'FRUITS', 'OLEAGINEUX') NOT NULL,
    `saison_culture` VARCHAR(100) NULL,
    `duree_jours` INTEGER NULL,
    `ph_optimal` DECIMAL(3, 1) NULL,
    `temperature_min` DECIMAL(4, 1) NULL,
    `temperature_max` DECIMAL(4, 1) NULL,
    `image_url` TEXT NULL,
    `rendement_moyen` DECIMAL(10, 2) NULL DEFAULT 0,
    `rendement_optimal` DECIMAL(10, 2) NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `cultures_nom_key`(`nom`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rendements_par_culture` (
    `id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NOT NULL,
    `culture_id` VARCHAR(191) NOT NULL,
    `annee` INTEGER NOT NULL,
    `rendement_kg_ha` DECIMAL(10, 2) NOT NULL,
    `qualite` VARCHAR(50) NULL,
    `notes` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `rendements_par_culture_parcelle_id_idx`(`parcelle_id`),
    INDEX `rendements_par_culture_culture_id_idx`(`culture_id`),
    INDEX `rendements_par_culture_annee_idx`(`annee`),
    UNIQUE INDEX `rendements_par_culture_parcelle_id_culture_id_annee_key`(`parcelle_id`, `culture_id`, `annee`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `roi_tracking` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NULL,
    `periode_debut` DATE NOT NULL,
    `periode_fin` DATE NOT NULL,
    `cout_semences` DECIMAL(10, 2) NULL,
    `cout_engrais` DECIMAL(10, 2) NULL,
    `cout_pesticides` DECIMAL(10, 2) NULL,
    `cout_irrigation` DECIMAL(10, 2) NULL,
    `cout_main_oeuvre` DECIMAL(10, 2) NULL,
    `autres_couts` DECIMAL(10, 2) NULL,
    `quantite_recoltee` DECIMAL(10, 2) NULL,
    `prix_vente_unitaire` DECIMAL(12, 2) NULL,
    `roi_trend` VARCHAR(20) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `roi_tracking_user_id_idx`(`user_id`),
    INDEX `roi_tracking_parcelle_id_idx`(`parcelle_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `activities_log` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `metadata` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `activities_log_user_id_created_at_idx`(`user_id`, `created_at`),
    INDEX `activities_log_action_idx`(`action`),
    INDEX `activities_log_created_at_idx`(`created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `audit_logs` (
    `id` VARCHAR(191) NOT NULL,
    `table_name` VARCHAR(100) NOT NULL,
    `record_id` VARCHAR(191) NOT NULL,
    `action` VARCHAR(20) NOT NULL,
    `old_data` JSON NULL,
    `new_data` JSON NULL,
    `user_id` VARCHAR(191) NULL,
    `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `audit_logs_table_name_record_id_idx`(`table_name`, `record_id`),
    INDEX `audit_logs_user_id_idx`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notifications` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `lue` BOOLEAN NOT NULL DEFAULT false,
    `metadata` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `notifications_user_id_lue_idx`(`user_id`, `lue`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `location_materiel` (
    `id` VARCHAR(191) NOT NULL,
    `locataire_id` VARCHAR(191) NOT NULL,
    `materiel` VARCHAR(255) NOT NULL,
    `date_debut` DATE NOT NULL,
    `date_fin` DATE NOT NULL,
    `cout_journalier` DECIMAL(10, 2) NOT NULL,
    `montant_total` DECIMAL(12, 2) NOT NULL,
    `statut` VARCHAR(50) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `location_materiel_locataire_id_idx`(`locataire_id`),
    INDEX `location_materiel_date_debut_date_fin_idx`(`date_debut`, `date_fin`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `badges` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `icone` VARCHAR(255) NULL,
    `condition` JSON NOT NULL,
    `points` INTEGER NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `badges_nom_key`(`nom`),
    INDEX `badges_is_active_idx`(`is_active`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_badges` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `badge_id` VARCHAR(191) NOT NULL,
    `obtenu_le` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `user_badges_user_id_idx`(`user_id`),
    INDEX `user_badges_badge_id_idx`(`badge_id`),
    UNIQUE INDEX `user_badges_user_id_badge_id_key`(`user_id`, `badge_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `refresh_tokens` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `token` TEXT NOT NULL,
    `expires_at` DATETIME(3) NOT NULL,
    `revoked` BOOLEAN NOT NULL DEFAULT false,
    `revoked_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `refresh_tokens_user_id_idx`(`user_id`),
    INDEX `refresh_tokens_token_idx`(`token`(100)),
    INDEX `refresh_tokens_user_id_revoked_idx`(`user_id`, `revoked`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `realisations` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `objectif` JSON NOT NULL,
    `points` INTEGER NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `deleted_at` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `realisations_nom_key`(`nom`),
    INDEX `realisations_is_active_idx`(`is_active`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_realisations` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `realisation_id` VARCHAR(191) NOT NULL,
    `progression` INTEGER NOT NULL DEFAULT 0,
    `complete` BOOLEAN NOT NULL DEFAULT false,
    `complete_le` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `user_realisations_user_id_idx`(`user_id`),
    INDEX `user_realisations_realisation_id_idx`(`realisation_id`),
    UNIQUE INDEX `user_realisations_user_id_realisation_id_key`(`user_id`, `realisation_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `configuration` (
    `cle` VARCHAR(191) NOT NULL,
    `valeur` TEXT NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`cle`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recommandations` (
    `id` VARCHAR(191) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `priorite` INTEGER NOT NULL DEFAULT 3,
    `parcelle_id` VARCHAR(191) NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `genere_par` VARCHAR(50) NOT NULL DEFAULT 'automatique',
    `valide_du` DATETIME(3) NULL,
    `valide_jusqu_au` DATETIME(3) NULL,
    `appliquee` BOOLEAN NOT NULL DEFAULT false,
    `date_application` DATETIME(3) NULL,
    `commentaire_utilisateur` TEXT NULL,
    `note_utilisateur` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `recommandations_parcelle_id_idx`(`parcelle_id`),
    INDEX `recommandations_user_id_idx`(`user_id`),
    INDEX `recommandations_user_id_appliquee_idx`(`user_id`, `appliquee`),
    INDEX `recommandations_type_idx`(`type`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `plantations` (
    `id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NOT NULL,
    `culture_id` VARCHAR(191) NOT NULL,
    `date_plantation` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `date_recolte` DATETIME(3) NULL,
    `date_fin` DATETIME(3) NULL,
    `statut` VARCHAR(50) NOT NULL DEFAULT 'active',
    `quantite_plantee` DECIMAL(10, 2) NULL,
    `rendement_par_hectare` DECIMAL(10, 2) NULL,
    `est_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `plantations_parcelle_id_idx`(`parcelle_id`),
    INDEX `plantations_culture_id_idx`(`culture_id`),
    INDEX `plantations_date_fin_idx`(`date_fin`),
    INDEX `plantations_est_active_parcelle_id_idx`(`est_active`, `parcelle_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `transactions_paiement` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `commande_id` VARCHAR(191) NULL,
    `location_id` VARCHAR(191) NULL,
    `achat_groupe_id` VARCHAR(191) NULL,
    `montant` DECIMAL(12, 2) NOT NULL,
    `fournisseur` VARCHAR(50) NOT NULL,
    `numero_telephone` VARCHAR(20) NOT NULL,
    `reference_paiement` VARCHAR(100) NOT NULL,
    `statut` VARCHAR(50) NOT NULL DEFAULT 'en_attente',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `transactions_paiement_reference_paiement_key`(`reference_paiement`),
    INDEX `transactions_paiement_user_id_idx`(`user_id`),
    INDEX `transactions_paiement_statut_idx`(`statut`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `equipements_location` (
    `id` VARCHAR(191) NOT NULL,
    `proprietaire_id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(200) NOT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `description` TEXT NOT NULL,
    `prix_jour` DECIMAL(10, 2) NOT NULL,
    `caution` DECIMAL(10, 2) NOT NULL DEFAULT 0,
    `etat` VARCHAR(50) NOT NULL DEFAULT 'bon',
    `localisation` VARCHAR(255) NOT NULL,
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `disponible` BOOLEAN NOT NULL DEFAULT true,
    `images` JSON NULL,
    `specifications` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `equipements_location_proprietaire_id_idx`(`proprietaire_id`),
    INDEX `equipements_location_disponible_categorie_idx`(`disponible`, `categorie`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `locations` (
    `id` VARCHAR(191) NOT NULL,
    `equipement_id` VARCHAR(191) NOT NULL,
    `locataire_id` VARCHAR(191) NOT NULL,
    `date_debut` DATE NOT NULL,
    `date_fin` DATE NOT NULL,
    `duree_jours` INTEGER NOT NULL,
    `prix_total` DECIMAL(12, 2) NOT NULL,
    `caution_versee` DECIMAL(12, 2) NOT NULL DEFAULT 0,
    `statut` VARCHAR(50) NOT NULL DEFAULT 'demande',
    `commentaire_proprietaire` TEXT NULL,
    `commentaire_locataire` TEXT NULL,
    `evaluation_note` INTEGER NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `locations_equipement_id_idx`(`equipement_id`),
    INDEX `locations_locataire_id_idx`(`locataire_id`),
    INDEX `locations_statut_idx`(`statut`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `achats_groupes` (
    `id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `prix_unitaire` DECIMAL(12, 2) NOT NULL,
    `prix_groupe` DECIMAL(12, 2) NOT NULL,
    `quantite_objectif` INTEGER NOT NULL,
    `quantite_actuelle` INTEGER NOT NULL DEFAULT 0,
    `min_par_personne` INTEGER NOT NULL DEFAULT 1,
    `date_limite` DATETIME(3) NOT NULL,
    `image` TEXT NULL,
    `statut` VARCHAR(50) NOT NULL DEFAULT 'en_cours',
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `achats_groupes_statut_date_limite_idx`(`statut`, `date_limite`),
    INDEX `achats_groupes_categorie_idx`(`categorie`),
    INDEX `achats_groupes_created_at_idx`(`created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `participations_achat_groupe` (
    `id` VARCHAR(191) NOT NULL,
    `achat_groupe_id` VARCHAR(191) NOT NULL,
    `participant_id` VARCHAR(191) NOT NULL,
    `quantite` INTEGER NOT NULL,
    `montant` DECIMAL(12, 2) NOT NULL,
    `statut` VARCHAR(50) NOT NULL DEFAULT 'confirme',
    `date_participation` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `participations_achat_groupe_achat_groupe_id_idx`(`achat_groupe_id`),
    INDEX `participations_achat_groupe_participant_id_idx`(`participant_id`),
    UNIQUE INDEX `participations_achat_groupe_achat_groupe_id_participant_id_key`(`achat_groupe_id`, `participant_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `maladies` (
    `id` VARCHAR(191) NOT NULL,
    `nom` VARCHAR(100) NOT NULL,
    `nom_scientifique` VARCHAR(150) NULL,
    `type` VARCHAR(50) NOT NULL,
    `description` TEXT NOT NULL,
    `symptomes` TEXT NOT NULL,
    `traitements` JSON NULL,
    `prevention` JSON NULL,
    `cultures_affectees` JSON NULL,
    `images` JSON NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `maladies_nom_key`(`nom`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `detections_maladies` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NULL,
    `culture_id` VARCHAR(191) NULL,
    `image_url` TEXT NOT NULL,
    `maladie_detectee_id` VARCHAR(191) NULL,
    `confiance` DECIMAL(5, 4) NOT NULL,
    `description` TEXT NULL,
    `resultats_bruts` JSON NULL,
    `confirme` BOOLEAN NOT NULL DEFAULT false,
    `maladie_corrigee_id` VARCHAR(191) NULL,
    `notes_correction` TEXT NULL,
    `date_confirmation` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `detections_maladies_user_id_idx`(`user_id`),
    INDEX `detections_maladies_parcelle_id_idx`(`parcelle_id`),
    INDEX `detections_maladies_maladie_detectee_id_idx`(`maladie_detectee_id`),
    INDEX `detections_maladies_confirme_created_at_idx`(`confirme`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `fiches_pratiques` (
    `id` VARCHAR(191) NOT NULL,
    `titre` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `categorie` VARCHAR(100) NOT NULL,
    `langue` VARCHAR(10) NOT NULL DEFAULT 'fr',
    `contenu` TEXT NULL,
    `fichier_url` TEXT NULL,
    `est_public` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_formations` (
    `user_id` VARCHAR(191) NOT NULL,
    `formation_id` VARCHAR(191) NOT NULL,
    `progress_pourcentage` INTEGER NOT NULL DEFAULT 0,
    `temps_visionne` INTEGER NOT NULL DEFAULT 0,
    `est_terminee` BOOLEAN NOT NULL DEFAULT false,
    `dernier_acces` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `note` INTEGER NULL,
    `commentaire` TEXT NULL,

    PRIMARY KEY (`user_id`, `formation_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `economies` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `eau_economisee_pourcentage` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `engrais_economise_pourcentage` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `pertes_evitees_pourcentage` DECIMAL(5, 2) NOT NULL DEFAULT 0,
    `valeur_eau_economisee_fcfa` DECIMAL(15, 2) NOT NULL DEFAULT 0,
    `valeur_engrais_economise_fcfa` DECIMAL(15, 2) NOT NULL DEFAULT 0,
    `valeur_pertes_evitees_fcfa` DECIMAL(15, 2) NOT NULL DEFAULT 0,
    `economies_totales_fcfa` DECIMAL(15, 2) NOT NULL DEFAULT 0,
    `date_debut` DATETIME(3) NOT NULL,
    `date_fin` DATETIME(3) NOT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `economies_user_id_idx`(`user_id`),
    INDEX `economies_date_fin_idx`(`date_fin`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `recoltes` (
    `id` VARCHAR(191) NOT NULL,
    `plantation_id` VARCHAR(191) NOT NULL,
    `quantite_kg` DECIMAL(10, 2) NOT NULL,
    `rendement_par_hectare` DECIMAL(10, 2) NULL,
    `qualite` VARCHAR(50) NULL,
    `date_recolte` DATETIME(3) NOT NULL,
    `notes` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `recoltes_plantation_id_idx`(`plantation_id`),
    INDEX `recoltes_date_recolte_idx`(`date_recolte`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `performance_parcelles` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NOT NULL,
    `annee` INTEGER NOT NULL,
    `rendement_moyen` DECIMAL(10, 2) NULL,
    `score_qualite_sol` DECIMAL(5, 2) NULL,
    `meilleure_pratique` TEXT NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `performance_parcelles_user_id_idx`(`user_id`),
    INDEX `performance_parcelles_annee_idx`(`annee`),
    UNIQUE INDEX `performance_parcelles_parcelle_id_annee_key`(`parcelle_id`, `annee`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stocks` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NULL,
    `nom` VARCHAR(200) NOT NULL,
    `categorie` ENUM('SEMENCES', 'ENGRAIS', 'PESTICIDES', 'HERBICIDES', 'OUTILS', 'RECOLTES', 'AUTRES') NOT NULL,
    `type` VARCHAR(100) NOT NULL,
    `quantite` DECIMAL(10, 2) NOT NULL,
    `unite` VARCHAR(20) NOT NULL,
    `seuil_alerte` DECIMAL(10, 2) NOT NULL,
    `prix_unitaire` DECIMAL(10, 2) NULL,
    `date_achat` DATE NULL,
    `date_expiration` DATE NULL,
    `fournisseur` VARCHAR(200) NULL,
    `localisation` VARCHAR(200) NULL,
    `notes` TEXT NULL,
    `est_actif` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `stocks_user_id_idx`(`user_id`),
    INDEX `stocks_parcelle_id_idx`(`parcelle_id`),
    INDEX `stocks_categorie_idx`(`categorie`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `mouvements_stock` (
    `id` VARCHAR(191) NOT NULL,
    `stock_id` VARCHAR(191) NOT NULL,
    `type_mouvement` ENUM('ENTREE', 'SORTIE', 'AJUSTEMENT', 'PERTE') NOT NULL,
    `quantite` DECIMAL(10, 2) NOT NULL,
    `quantite_avant` DECIMAL(10, 2) NOT NULL,
    `quantite_apres` DECIMAL(10, 2) NOT NULL,
    `motif` TEXT NULL,
    `reference` VARCHAR(100) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `mouvements_stock_stock_id_idx`(`stock_id`),
    INDEX `mouvements_stock_type_mouvement_idx`(`type_mouvement`),
    INDEX `mouvements_stock_created_at_idx`(`created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `alertes_stock` (
    `id` VARCHAR(191) NOT NULL,
    `stock_id` VARCHAR(191) NOT NULL,
    `type_alerte` ENUM('STOCK_BAS', 'EXPIRATION_PROCHE', 'STOCK_EPUISE') NOT NULL,
    `message` TEXT NOT NULL,
    `est_lue` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `alertes_stock_stock_id_idx`(`stock_id`),
    INDEX `alertes_stock_est_lue_idx`(`est_lue`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `meteo` (
    `id` VARCHAR(191) NOT NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `temperature` DECIMAL(5, 2) NOT NULL,
    `humidite_air` DECIMAL(5, 2) NOT NULL,
    `pression` DECIMAL(8, 2) NULL,
    `vitesse_vent` DECIMAL(5, 2) NULL,
    `direction_vent` DECIMAL(10, 2) NULL,
    `description` VARCHAR(255) NULL,
    `observation_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `source` VARCHAR(50) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `meteo_latitude_longitude_idx`(`latitude`, `longitude`),
    INDEX `meteo_observation_at_idx`(`observation_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `calendrier_activites` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `parcelle_id` VARCHAR(191) NULL,
    `titre` VARCHAR(255) NOT NULL,
    `description` TEXT NULL,
    `type_activite` ENUM('SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 'TRAITEMENT', 'DESHERBAGE', 'TAILLE', 'RECOLTE', 'AUTRE') NOT NULL,
    `statut` ENUM('PLANIFIEE', 'EN_COURS', 'TERMINEE', 'ANNULEE', 'REPORTEE') NOT NULL DEFAULT 'PLANIFIEE',
    `priorite` ENUM('BASSE', 'MOYENNE', 'HAUTE', 'URGENTE') NOT NULL DEFAULT 'MOYENNE',
    `date_debut` DATETIME(3) NOT NULL,
    `date_fin` DATETIME(3) NULL,
    `date_rappel` DATETIME(3) NULL,
    `est_recurrente` BOOLEAN NOT NULL DEFAULT false,
    `frequence_jours` INTEGER NULL,
    `date_fin_recurrence` DATETIME(3) NULL,
    `cout_estime` DECIMAL(10, 2) NULL,
    `notes_techniques` TEXT NULL,
    `produits_utilises` TEXT NULL,
    `rappel_envoye` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    INDEX `calendrier_activites_user_id_idx`(`user_id`),
    INDEX `calendrier_activites_parcelle_id_idx`(`parcelle_id`),
    INDEX `calendrier_activites_type_activite_idx`(`type_activite`),
    INDEX `calendrier_activites_statut_idx`(`statut`),
    INDEX `calendrier_activites_date_debut_idx`(`date_debut`),
    INDEX `calendrier_activites_date_rappel_idx`(`date_rappel`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_points` (
    `id` VARCHAR(191) NOT NULL,
    `user_id` VARCHAR(191) NOT NULL,
    `points_total` INTEGER NOT NULL DEFAULT 0,
    `niveau` INTEGER NOT NULL DEFAULT 1,
    `actions_completees` INTEGER NOT NULL DEFAULT 0,
    `derniere_activite` DATETIME(3) NULL,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    UNIQUE INDEX `user_points_user_id_key`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `conversations` (
    `id` VARCHAR(191) NOT NULL,
    `type` VARCHAR(20) NOT NULL DEFAULT 'prive',
    `nom` VARCHAR(255) NULL,
    `participants` JSON NOT NULL,
    `admin_id` VARCHAR(191) NULL,
    `est_actif` BOOLEAN NOT NULL DEFAULT true,
    `dernier_message_at` DATETIME(3) NULL,
    `nb_messages` INTEGER NOT NULL DEFAULT 0,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updated_at` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `cooperatives` ADD CONSTRAINT `cooperatives_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `regions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `users` ADD CONSTRAINT `users_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `regions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `password_history` ADD CONSTRAINT `password_history_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `otp_codes` ADD CONSTRAINT `otp_codes_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `parcelles` ADD CONSTRAINT `parcelles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `parcelles` ADD CONSTRAINT `parcelles_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `regions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stations` ADD CONSTRAINT `stations_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `capteurs` ADD CONSTRAINT `capteurs_station_id_fkey` FOREIGN KEY (`station_id`) REFERENCES `stations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `capteurs` ADD CONSTRAINT `capteurs_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `mesures` ADD CONSTRAINT `mesures_capteur_id_fkey` FOREIGN KEY (`capteur_id`) REFERENCES `capteurs`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `alertes` ADD CONSTRAINT `alertes_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `alertes` ADD CONSTRAINT `alertes_capteur_id_fkey` FOREIGN KEY (`capteur_id`) REFERENCES `capteurs`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `diagnostics` ADD CONSTRAINT `diagnostics_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `diagnostics` ADD CONSTRAINT `diagnostics_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `modules_formation` ADD CONSTRAINT `modules_formation_formation_id_fkey` FOREIGN KEY (`formation_id`) REFERENCES `formations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `progressions_formation` ADD CONSTRAINT `progressions_formation_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `progressions_formation` ADD CONSTRAINT `progressions_formation_formation_id_fkey` FOREIGN KEY (`formation_id`) REFERENCES `formations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `marketplace_produits` ADD CONSTRAINT `marketplace_produits_vendeur_id_fkey` FOREIGN KEY (`vendeur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `carts` ADD CONSTRAINT `carts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cart_items` ADD CONSTRAINT `cart_items_cart_id_fkey` FOREIGN KEY (`cart_id`) REFERENCES `carts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `cart_items` ADD CONSTRAINT `cart_items_produit_id_fkey` FOREIGN KEY (`produit_id`) REFERENCES `marketplace_produits`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `favorites` ADD CONSTRAINT `favorites_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `favorites` ADD CONSTRAINT `favorites_produit_id_fkey` FOREIGN KEY (`produit_id`) REFERENCES `marketplace_produits`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wishlists` ADD CONSTRAINT `wishlists_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wishlist_items` ADD CONSTRAINT `wishlist_items_wishlist_id_fkey` FOREIGN KEY (`wishlist_id`) REFERENCES `wishlists`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wishlist_items` ADD CONSTRAINT `wishlist_items_produit_id_fkey` FOREIGN KEY (`produit_id`) REFERENCES `marketplace_produits`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `avis` ADD CONSTRAINT `avis_produit_id_fkey` FOREIGN KEY (`produit_id`) REFERENCES `marketplace_produits`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `avis` ADD CONSTRAINT `avis_utilisateur_id_fkey` FOREIGN KEY (`utilisateur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `marketplace_commandes` ADD CONSTRAINT `marketplace_commandes_acheteur_id_fkey` FOREIGN KEY (`acheteur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `marketplace_commandes` ADD CONSTRAINT `marketplace_commandes_produit_id_fkey` FOREIGN KEY (`produit_id`) REFERENCES `marketplace_produits`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `marketplace_transactions` ADD CONSTRAINT `marketplace_transactions_commande_id_fkey` FOREIGN KEY (`commande_id`) REFERENCES `marketplace_commandes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `forum_posts` ADD CONSTRAINT `forum_posts_auteur_id_fkey` FOREIGN KEY (`auteur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `forum_reponses` ADD CONSTRAINT `forum_reponses_post_id_fkey` FOREIGN KEY (`post_id`) REFERENCES `forum_posts`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `forum_reponses` ADD CONSTRAINT `forum_reponses_auteur_id_fkey` FOREIGN KEY (`auteur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_conversation_id_fkey` FOREIGN KEY (`conversation_id`) REFERENCES `conversations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_expediteur_id_fkey` FOREIGN KEY (`expediteur_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `messages` ADD CONSTRAINT `messages_destinataire_id_fkey` FOREIGN KEY (`destinataire_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rendements_par_culture` ADD CONSTRAINT `rendements_par_culture_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rendements_par_culture` ADD CONSTRAINT `rendements_par_culture_culture_id_fkey` FOREIGN KEY (`culture_id`) REFERENCES `cultures`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `roi_tracking` ADD CONSTRAINT `roi_tracking_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `roi_tracking` ADD CONSTRAINT `roi_tracking_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `activities_log` ADD CONSTRAINT `activities_log_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `audit_logs` ADD CONSTRAINT `audit_logs_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notifications` ADD CONSTRAINT `notifications_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `location_materiel` ADD CONSTRAINT `location_materiel_locataire_id_fkey` FOREIGN KEY (`locataire_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_badges` ADD CONSTRAINT `user_badges_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_badges` ADD CONSTRAINT `user_badges_badge_id_fkey` FOREIGN KEY (`badge_id`) REFERENCES `badges`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `refresh_tokens` ADD CONSTRAINT `refresh_tokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_realisations` ADD CONSTRAINT `user_realisations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_realisations` ADD CONSTRAINT `user_realisations_realisation_id_fkey` FOREIGN KEY (`realisation_id`) REFERENCES `realisations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommandations` ADD CONSTRAINT `recommandations_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recommandations` ADD CONSTRAINT `recommandations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `plantations` ADD CONSTRAINT `plantations_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `plantations` ADD CONSTRAINT `plantations_culture_id_fkey` FOREIGN KEY (`culture_id`) REFERENCES `cultures`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions_paiement` ADD CONSTRAINT `transactions_paiement_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `equipements_location` ADD CONSTRAINT `equipements_location_proprietaire_id_fkey` FOREIGN KEY (`proprietaire_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `locations` ADD CONSTRAINT `locations_equipement_id_fkey` FOREIGN KEY (`equipement_id`) REFERENCES `equipements_location`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `locations` ADD CONSTRAINT `locations_locataire_id_fkey` FOREIGN KEY (`locataire_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `participations_achat_groupe` ADD CONSTRAINT `participations_achat_groupe_achat_groupe_id_fkey` FOREIGN KEY (`achat_groupe_id`) REFERENCES `achats_groupes`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `participations_achat_groupe` ADD CONSTRAINT `participations_achat_groupe_participant_id_fkey` FOREIGN KEY (`participant_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detections_maladies` ADD CONSTRAINT `detections_maladies_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detections_maladies` ADD CONSTRAINT `detections_maladies_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detections_maladies` ADD CONSTRAINT `detections_maladies_culture_id_fkey` FOREIGN KEY (`culture_id`) REFERENCES `cultures`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detections_maladies` ADD CONSTRAINT `detections_maladies_maladie_detectee_id_fkey` FOREIGN KEY (`maladie_detectee_id`) REFERENCES `maladies`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detections_maladies` ADD CONSTRAINT `detections_maladies_maladie_corrigee_id_fkey` FOREIGN KEY (`maladie_corrigee_id`) REFERENCES `maladies`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `economies` ADD CONSTRAINT `economies_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `recoltes` ADD CONSTRAINT `recoltes_plantation_id_fkey` FOREIGN KEY (`plantation_id`) REFERENCES `plantations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `performance_parcelles` ADD CONSTRAINT `performance_parcelles_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `performance_parcelles` ADD CONSTRAINT `performance_parcelles_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stocks` ADD CONSTRAINT `stocks_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stocks` ADD CONSTRAINT `stocks_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `mouvements_stock` ADD CONSTRAINT `mouvements_stock_stock_id_fkey` FOREIGN KEY (`stock_id`) REFERENCES `stocks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `alertes_stock` ADD CONSTRAINT `alertes_stock_stock_id_fkey` FOREIGN KEY (`stock_id`) REFERENCES `stocks`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `calendrier_activites` ADD CONSTRAINT `calendrier_activites_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `calendrier_activites` ADD CONSTRAINT `calendrier_activites_parcelle_id_fkey` FOREIGN KEY (`parcelle_id`) REFERENCES `parcelles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_points` ADD CONSTRAINT `user_points_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;


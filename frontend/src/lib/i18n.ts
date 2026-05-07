import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'

const resources = {
  fr: {
    translation: {
      // Navigation
      nav: {
        dashboard: 'Tableau de bord',
        parcelles: 'Mes Parcelles',
        capteurs: 'Capteurs',
        alertes: 'Alertes',
        recommandations: 'Recommandations',
        marketplace: 'Marketplace',
        formations: 'Formations',
        messages: 'Messages',
        settings: 'Paramètres',
        logout: 'Déconnexion',
      },
      // Auth
      auth: {
        login: 'Connexion',
        register: "S'inscrire",
        phone: 'Numéro de téléphone',
        password: 'Mot de passe',
        confirmPassword: 'Confirmer le mot de passe',
        firstName: 'Prénom',
        lastName: 'Nom',
        email: 'Email (optionnel)',
        otpTitle: 'Vérification OTP',
        otpMessage: 'Entrez le code à 6 chiffres envoyé à votre téléphone',
        otpCode: 'Code OTP',
        verify: 'Vérifier',
        resendOtp: 'Renvoyer le code',
        forgotPassword: 'Mot de passe oublié ?',
        noAccount: "Pas encore de compte ?",
        hasAccount: 'Déjà un compte ?',
      },
      // Dashboard
      dashboard: {
        title: 'Tableau de bord',
        welcome: 'Bienvenue',
        parcelles: 'Parcelles',
        alertes: 'Alertes actives',
        capteurs: 'Capteurs actifs',
        rendement: 'Rendement moyen',
        meteo: 'Météo',
        recentAlerts: 'Alertes récentes',
        recommendations: 'Recommandations',
        soilStatus: 'État du sol',
        humidity: 'Humidité',
        temperature: 'Température',
        ph: 'pH',
        npk: 'NPK',
      },
      // Parcelles
      parcelles: {
        title: 'Mes Parcelles',
        add: 'Ajouter une parcelle',
        edit: 'Modifier',
        delete: 'Supprimer',
        name: 'Nom de la parcelle',
        surface: 'Superficie (ha)',
        soilType: 'Type de sol',
        description: 'Description',
        status: 'Statut',
        coordinates: 'Coordonnées GPS',
        latitude: 'Latitude',
        longitude: 'Longitude',
        stations: 'Stations',
        plantations: 'Plantations',
        noData: 'Aucune parcelle trouvée',
        soilTypes: {
          argileux: 'Argileux',
          sablonneux: 'Sablonneux',
          limono_argileux: 'Limono-argileux',
          limoneux: 'Limoneux',
          argilo_sableux: 'Argilo-sableux',
        },
      },
      // Capteurs
      capteurs: {
        title: 'Capteurs',
        add: 'Ajouter un capteur',
        type: 'Type',
        station: 'Station',
        status: 'Statut',
        lastMeasure: 'Dernière mesure',
        types: {
          humidite: 'Humidité',
          temperature: 'Température',
          ph: 'pH',
          npk: 'NPK',
          meteo: 'Météo',
          camera: 'Caméra',
        },
      },
      // Alertes
      alertes: {
        title: 'Alertes',
        all: 'Toutes',
        critical: 'Critiques',
        important: 'Importantes',
        info: 'Informatives',
        markRead: 'Marquer comme lue',
        markProcessed: 'Marquer comme traitée',
        levels: {
          critique: 'Critique',
          important: 'Important',
          info: 'Information',
        },
      },
      // Recommandations
      recommandations: {
        title: 'Recommandations',
        apply: 'Appliquer',
        applied: 'Appliquée',
        types: {
          irrigation: 'Irrigation',
          fertilisation: 'Fertilisation',
          traitement: 'Traitement',
          recolte: 'Récolte',
        },
      },
      // Marketplace
      marketplace: {
        title: 'Marketplace',
        products: 'Produits',
        myProducts: 'Mes produits',
        orders: 'Commandes',
        addProduct: 'Ajouter un produit',
        price: 'Prix',
        quantity: 'Quantité',
        category: 'Catégorie',
        buy: 'Acheter',
        contact: 'Contacter le vendeur',
        categories: {
          semences: 'Semences',
          engrais: 'Engrais',
          recoltes: 'Récoltes',
          equipement: 'Équipement',
          intrant: 'Intrants',
          legume: 'Légumes',
          fruit: 'Fruits',
        },
      },
      // Formations
      formations: {
        title: 'Formations',
        start: 'Commencer',
        continue: 'Continuer',
        completed: 'Terminée',
        progress: 'Progression',
        duration: 'Durée',
        categories: {
          culture: 'Culture',
          irrigation: 'Irrigation',
          maladie: 'Maladies',
          sol: 'Sol',
          application: 'Application',
        },
      },
      // Messages
      messages: {
        title: 'Messages',
        newMessage: 'Nouveau message',
        send: 'Envoyer',
        placeholder: 'Écrivez votre message...',
        noMessages: 'Aucun message',
      },
      // Common
      common: {
        save: 'Enregistrer',
        cancel: 'Annuler',
        delete: 'Supprimer',
        edit: 'Modifier',
        add: 'Ajouter',
        search: 'Rechercher',
        filter: 'Filtrer',
        loading: 'Chargement...',
        error: 'Erreur',
        success: 'Succès',
        confirm: 'Confirmer',
        back: 'Retour',
        next: 'Suivant',
        previous: 'Précédent',
        viewMore: 'Voir plus',
        noData: 'Aucune donnée',
        actions: 'Actions',
      },
      // Status
      status: {
        active: 'Actif',
        inactive: 'Inactif',
        maintenance: 'Maintenance',
        defaillant: 'Défaillant',
      },
      // Errors
      errors: {
        required: 'Ce champ est requis',
        invalidPhone: 'Numéro de téléphone invalide',
        invalidEmail: 'Email invalide',
        minLength: 'Minimum {{min}} caractères',
        passwordMatch: 'Les mots de passe ne correspondent pas',
        serverError: 'Erreur serveur, veuillez réessayer',
        networkError: 'Erreur de connexion',
      },
    },
  },
  baoule: {
    translation: {
      nav: {
        dashboard: 'Bue like',
        parcelles: 'Min fie mun',
        capteurs: 'Capteurs',
        alertes: 'Alertes',
        recommandations: 'Afɔtuɛ',
        marketplace: 'Ahi plɛ',
        formations: 'Sukalɛ',
        messages: 'Ndɛ',
        settings: 'Siesie',
        logout: 'Fite',
      },
      dashboard: {
        welcome: 'Ɛ mo klo',
        humidity: 'Nzue',
        temperature: 'Wawa',
      },
      common: {
        save: 'Sie',
        cancel: 'Yaci',
        loading: 'É su kɔ...',
      },
    },
  },
  malinke: {
    translation: {
      nav: {
        dashboard: 'Kunnafonw',
        parcelles: 'N ka foro',
        alertes: 'Laseli',
        marketplace: 'Sugu',
        formations: 'Kalanko',
        messages: 'Kumakan',
        logout: 'Bɔ',
      },
      dashboard: {
        welcome: 'Bissimila',
        humidity: 'Ji',
        temperature: 'Funteni',
      },
      common: {
        save: 'A mara',
        cancel: 'A dabila',
        loading: 'A bɛ se...',
      },
    },
  },
  senoufo: {
    translation: {
      nav: {
        dashboard: 'Kafugeye',
        parcelles: 'Na foroge',
        marketplace: 'Jagaso',
        logout: 'Wolo',
      },
      dashboard: {
        welcome: 'I ni che',
      },
      common: {
        save: 'A sogo',
        cancel: 'A bila',
      },
    },
  },
}

i18n.use(initReactI18next).init({
  resources,
  lng: 'fr',
  fallbackLng: 'fr',
  interpolation: {
    escapeValue: false,
  },
})

export default i18n

import js from "@eslint/js";
import globals from "globals";

export default [
    js.configs.recommended,
    {
        languageOptions: {
            ecmaVersion: "latest",
            sourceType: "module",
            globals: {
                ...globals.node,
                ...globals.jest,
            },
        },
        rules: {
            "no-unused-vars": "off",
            "no-console": "off",
        },
    },
    // Configuration spéciale pour les fichiers k6
    {
        files: ["tests/load/**/*.js"],
        languageOptions: {
            globals: {
                __ENV: "readonly",
                open: "readonly",
            },
        },
    },
    {
        ignores: ["node_modules/", "dist/", "coverage/", "tests/load/"],
    },
];

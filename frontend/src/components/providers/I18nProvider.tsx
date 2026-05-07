'use client';

import { useEffect } from 'react';
import i18n from '@/lib/i18n';

export function I18nProvider({ children }: { children: React.ReactNode }) {
    useEffect(() => {
        // i18n is already initialized in i18n.ts, this just ensures it's loaded
        i18n.loadNamespaces('translation');
    }, []);

    return <>{children}</>;
}

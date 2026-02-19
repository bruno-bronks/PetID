import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
    id: number;
    email: string;
    is_active: boolean;
    is_superuser: boolean;
    full_name: string;
    phone?: string | null;
}

interface AuthState {
    token: string | null;
    user: User | null;
    setAuth: (token: string, user: User) => void;
    setUser: (user: User) => void;
    logout: () => void;
    isAuthenticated: () => boolean;
}

export const useAuthStore = create<AuthState>()(
    persist(
        (set, get) => ({
            token: null,
            user: null,
            setAuth: (token, user) => set({ token, user }),
            setUser: (user) => set({ user }),
            logout: () => set({ token: null, user: null }),
            isAuthenticated: () => !!get().token,
        }),
        {
            name: 'auth-storage',
        }
    )
);

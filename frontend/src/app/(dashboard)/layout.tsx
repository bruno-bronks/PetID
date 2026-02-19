'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuthStore } from '@/stores/useAuthStore';
import { useRouter } from 'next/navigation';
import {
    PawPrint,
    LayoutDashboard,
    Users,
    Settings,
    LogOut,
    Menu,
    AlertTriangle,
    UserCircle,
    Activity,
} from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import { ThemeToggle } from '@/components/ThemeToggle';
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';

const navItems = [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/pets', label: 'Pets', icon: PawPrint },
    { href: '/lost-pets', label: 'Pets Perdidos', icon: AlertTriangle },
    { href: '/users', label: 'Usuários', icon: Users },
    { href: '/activity', label: 'Atividade', icon: Activity },
    { href: '/settings', label: 'Configurações', icon: Settings },
];

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const pathname = usePathname();
    const router = useRouter();
    const { user, logout } = useAuthStore();

    const handleLogout = () => {
        logout();
        localStorage.removeItem('token');
        router.push('/login');
    };

    return (
        <div className="flex min-h-screen w-full flex-col md:flex-row bg-purple-50/30 dark:bg-gray-950">
            {/* Sidebar Desktop */}
            <aside className="hidden border-r bg-white dark:bg-gray-900 md:block md:w-64 lg:w-72">
                <div className="flex h-16 items-center border-b px-6">
                    <Link href="/pets" className="flex items-center gap-2 font-bold text-lg">
                        <PawPrint className="h-6 w-6 text-primary" />
                        <span>PetID Admin</span>
                    </Link>
                </div>
                <nav className="flex flex-col gap-1 p-4">
                    {navItems.map((item) => (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={`flex items-center gap-3 rounded-lg px-3 py-2 transition-all hover:bg-purple-100 dark:hover:bg-purple-900/30 ${pathname === item.href
                                ? 'bg-primary/10 text-primary font-medium'
                                : 'text-gray-500 dark:text-gray-400'
                                }`}
                        >
                            <item.icon className="h-5 w-5" />
                            {item.label}
                        </Link>
                    ))}
                </nav>
            </aside>

            <div className="flex flex-1 flex-col">
                {/* Header */}
                <header className="flex h-16 items-center justify-between border-b bg-white dark:bg-gray-900 px-6">
                    <div className="flex items-center gap-4 md:hidden">
                        <Sheet>
                            <SheetTrigger asChild>
                                <Button variant="ghost" size="icon" className="md:hidden">
                                    <Menu className="h-6 w-6" />
                                    <span className="sr-only">Menu</span>
                                </Button>
                            </SheetTrigger>
                            <SheetContent side="left" className="w-64 sm:max-w-xs">
                                <nav className="flex flex-col gap-4 mt-8">
                                    {navItems.map((item) => (
                                        <Link
                                            key={item.href}
                                            href={item.href}
                                            className={`flex items-center gap-3 text-lg font-medium px-2 py-1 rounded-md ${pathname === item.href ? 'text-primary' : 'text-gray-500 dark:text-gray-400'
                                                }`}
                                        >
                                            <item.icon className="h-5 w-5" />
                                            {item.label}
                                        </Link>
                                    ))}
                                </nav>
                            </SheetContent>
                        </Sheet>
                        <Link href="/pets" className="flex items-center gap-2 font-bold text-lg md:hidden">
                            <PawPrint className="h-6 w-6 text-primary" />
                            <span>PetID</span>
                        </Link>
                    </div>

                    <div className="flex flex-1 items-center justify-end gap-4">
                        <ThemeToggle />
                        <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                                <Button variant="ghost" className="relative h-9 w-9 rounded-full">
                                    <Avatar className="h-9 w-9">
                                        <AvatarImage src="" alt={user?.full_name || 'User'} />
                                        <AvatarFallback>{user?.full_name?.charAt(0) || 'U'}</AvatarFallback>
                                    </Avatar>
                                </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                                <DropdownMenuLabel>Minha Conta</DropdownMenuLabel>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem asChild className="cursor-pointer">
                                    <Link href="/profile">
                                        <UserCircle className="mr-2 h-4 w-4" />
                                        Meu Perfil
                                    </Link>
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem onClick={handleLogout} className="text-red-600 cursor-pointer">
                                    <LogOut className="mr-2 h-4 w-4" />
                                    Sair
                                </DropdownMenuItem>
                            </DropdownMenuContent>
                        </DropdownMenu>
                    </div>
                </header>

                {/* Content */}
                <main className="flex-1 p-6 overflow-y-auto">
                    {children}
                </main>
            </div>
        </div>
    );
}

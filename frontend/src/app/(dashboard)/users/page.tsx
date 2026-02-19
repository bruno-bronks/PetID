'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Loader2, Users, UserCheck, UserX, Shield, ShieldOff, Search } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import { useAuthStore } from '@/stores/useAuthStore';

interface UserItem {
    id: number;
    email: string;
    full_name: string;
    is_active: boolean;
    is_superuser: boolean;
    created_at: string;
    phone?: string | null;
}

export default function UsersPage() {
    const [search, setSearch] = useState('');
    const { user: currentUser } = useAuthStore();
    const queryClient = useQueryClient();

    const { data: users, isLoading } = useQuery<UserItem[]>({
        queryKey: ['users'],
        queryFn: async () => (await api.get('/auth/users')).data,
    });

    const toggleActiveMutation = useMutation({
        mutationFn: async ({ id, is_active }: { id: number; is_active: boolean }) =>
            api.patch(`/auth/users/${id}`, { is_active }),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
    });

    const toggleSuperuserMutation = useMutation({
        mutationFn: async ({ id, is_superuser }: { id: number; is_superuser: boolean }) =>
            api.patch(`/auth/users/${id}`, { is_superuser }),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
    });

    const filtered = users?.filter(
        (u) =>
            u.full_name.toLowerCase().includes(search.toLowerCase()) ||
            u.email.toLowerCase().includes(search.toLowerCase())
    ) ?? [];

    const activeCount = users?.filter((u) => u.is_active).length ?? 0;
    const adminCount = users?.filter((u) => u.is_superuser).length ?? 0;

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Usuários</h1>
                <p className="text-muted-foreground mt-1">Gerencie os usuários do sistema</p>
            </div>

            {/* Stats */}
            <div className="grid gap-4 sm:grid-cols-3">
                <Card>
                    <CardContent className="flex items-center gap-3 pt-6">
                        <Users className="h-5 w-5 text-muted-foreground" />
                        <div>
                            <p className="text-2xl font-bold">{users?.length ?? 0}</p>
                            <p className="text-xs text-muted-foreground">Total de usuários</p>
                        </div>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="flex items-center gap-3 pt-6">
                        <UserCheck className="h-5 w-5 text-green-500" />
                        <div>
                            <p className="text-2xl font-bold">{activeCount}</p>
                            <p className="text-xs text-muted-foreground">Ativos</p>
                        </div>
                    </CardContent>
                </Card>
                <Card>
                    <CardContent className="flex items-center gap-3 pt-6">
                        <Shield className="h-5 w-5 text-blue-500" />
                        <div>
                            <p className="text-2xl font-bold">{adminCount}</p>
                            <p className="text-xs text-muted-foreground">Administradores</p>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Table */}
            <Card>
                <CardHeader>
                    <CardTitle>Lista de Usuários</CardTitle>
                    <CardDescription>
                        Ative/desative contas e gerencie permissões de administrador.
                    </CardDescription>
                    <div className="relative max-w-sm pt-2">
                        <Search className="absolute left-2.5 top-5 h-4 w-4 text-muted-foreground" />
                        <Input
                            placeholder="Buscar por nome ou e-mail..."
                            className="pl-9"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                </CardHeader>
                <CardContent>
                    <div className="rounded-md border">
                        <Table>
                            <TableHeader>
                                <TableRow>
                                    <TableHead>Usuário</TableHead>
                                    <TableHead>Status</TableHead>
                                    <TableHead>Tipo</TableHead>
                                    <TableHead>Cadastro</TableHead>
                                    <TableHead className="text-right">Ações</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {isLoading ? (
                                    <TableRow>
                                        <TableCell colSpan={5} className="h-24 text-center">
                                            <Loader2 className="h-6 w-6 animate-spin mx-auto text-muted-foreground" />
                                        </TableCell>
                                    </TableRow>
                                ) : filtered.length === 0 ? (
                                    <TableRow>
                                        <TableCell colSpan={5} className="h-24 text-center text-muted-foreground">
                                            Nenhum usuário encontrado.
                                        </TableCell>
                                    </TableRow>
                                ) : (
                                    filtered.map((u) => (
                                        <TableRow key={u.id}>
                                            <TableCell>
                                                <div>
                                                    <p className="font-medium text-sm">{u.full_name}</p>
                                                    <p className="text-xs text-muted-foreground">{u.email}</p>
                                                </div>
                                            </TableCell>
                                            <TableCell>
                                                <Badge
                                                    variant={u.is_active ? 'default' : 'secondary'}
                                                    className="text-xs"
                                                >
                                                    {u.is_active ? 'Ativo' : 'Inativo'}
                                                </Badge>
                                            </TableCell>
                                            <TableCell>
                                                <Badge
                                                    variant={u.is_superuser ? 'default' : 'outline'}
                                                    className={`text-xs ${u.is_superuser ? 'bg-blue-600' : ''}`}
                                                >
                                                    {u.is_superuser ? '👑 Admin' : 'Usuário'}
                                                </Badge>
                                            </TableCell>
                                            <TableCell className="text-xs text-muted-foreground">
                                                {new Date(u.created_at).toLocaleDateString('pt-BR')}
                                            </TableCell>
                                            <TableCell className="text-right">
                                                <div className="flex justify-end gap-1">
                                                    {/* Toggle active */}
                                                    {u.id !== currentUser?.id && (
                                                        <AlertDialog>
                                                            <AlertDialogTrigger asChild>
                                                                <Button
                                                                    variant="ghost"
                                                                    size="sm"
                                                                    title={u.is_active ? 'Desativar' : 'Ativar'}
                                                                >
                                                                    {u.is_active ? (
                                                                        <UserX className="h-4 w-4 text-red-500" />
                                                                    ) : (
                                                                        <UserCheck className="h-4 w-4 text-green-500" />
                                                                    )}
                                                                </Button>
                                                            </AlertDialogTrigger>
                                                            <AlertDialogContent>
                                                                <AlertDialogHeader>
                                                                    <AlertDialogTitle>
                                                                        {u.is_active ? 'Desativar' : 'Ativar'} {u.full_name}?
                                                                    </AlertDialogTitle>
                                                                    <AlertDialogDescription>
                                                                        {u.is_active
                                                                            ? 'O usuário perderá acesso ao sistema.'
                                                                            : 'O usuário poderá acessar o sistema novamente.'}
                                                                    </AlertDialogDescription>
                                                                </AlertDialogHeader>
                                                                <AlertDialogFooter>
                                                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                                    <AlertDialogAction
                                                                        onClick={() =>
                                                                            toggleActiveMutation.mutate({
                                                                                id: u.id,
                                                                                is_active: !u.is_active,
                                                                            })
                                                                        }
                                                                    >
                                                                        Confirmar
                                                                    </AlertDialogAction>
                                                                </AlertDialogFooter>
                                                            </AlertDialogContent>
                                                        </AlertDialog>
                                                    )}
                                                    {/* Toggle superuser */}
                                                    {u.id !== currentUser?.id && (
                                                        <AlertDialog>
                                                            <AlertDialogTrigger asChild>
                                                                <Button
                                                                    variant="ghost"
                                                                    size="sm"
                                                                    title={u.is_superuser ? 'Remover admin' : 'Tornar admin'}
                                                                >
                                                                    {u.is_superuser ? (
                                                                        <ShieldOff className="h-4 w-4 text-orange-500" />
                                                                    ) : (
                                                                        <Shield className="h-4 w-4 text-blue-500" />
                                                                    )}
                                                                </Button>
                                                            </AlertDialogTrigger>
                                                            <AlertDialogContent>
                                                                <AlertDialogHeader>
                                                                    <AlertDialogTitle>
                                                                        {u.is_superuser ? 'Remover permissão de admin' : 'Tornar administrador'}?
                                                                    </AlertDialogTitle>
                                                                    <AlertDialogDescription>
                                                                        {u.is_superuser
                                                                            ? `${u.full_name} perderá privilégios de administrador.`
                                                                            : `${u.full_name} terá acesso total ao sistema.`}
                                                                    </AlertDialogDescription>
                                                                </AlertDialogHeader>
                                                                <AlertDialogFooter>
                                                                    <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                                    <AlertDialogAction
                                                                        onClick={() =>
                                                                            toggleSuperuserMutation.mutate({
                                                                                id: u.id,
                                                                                is_superuser: !u.is_superuser,
                                                                            })
                                                                        }
                                                                    >
                                                                        Confirmar
                                                                    </AlertDialogAction>
                                                                </AlertDialogFooter>
                                                            </AlertDialogContent>
                                                        </AlertDialog>
                                                    )}
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}

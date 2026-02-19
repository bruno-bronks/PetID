'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation } from '@tanstack/react-query';
import { Loader2, User, Lock, Save, Check } from 'lucide-react';
import api from '@/lib/axios';
import { useAuthStore } from '@/stores/useAuthStore';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';

// --------------- Profile form ---------------
const profileSchema = z.object({
    full_name: z.string().min(2, 'Nome deve ter ao menos 2 caracteres'),
    phone: z.string().optional(),
});
type ProfileValues = z.infer<typeof profileSchema>;

// --------------- Password form ---------------
const passwordSchema = z
    .object({
        current_password: z.string().min(1, 'Senha atual é obrigatória'),
        new_password: z.string().min(6, 'Nova senha deve ter ao menos 6 caracteres'),
        confirm_password: z.string().min(1, 'Confirmação é obrigatória'),
    })
    .refine((d) => d.new_password === d.confirm_password, {
        message: 'As senhas não coincidem',
        path: ['confirm_password'],
    });
type PasswordValues = z.infer<typeof passwordSchema>;

export default function ProfilePage() {
    const { user, setUser } = useAuthStore();
    const [profileSaved, setProfileSaved] = useState(false);
    const [passwordSaved, setPasswordSaved] = useState(false);

    const profileForm = useForm<ProfileValues>({
        resolver: zodResolver(profileSchema),
        defaultValues: {
            full_name: user?.full_name ?? '',
            phone: user?.phone ?? '',
        },
    });

    const passwordForm = useForm<PasswordValues>({
        resolver: zodResolver(passwordSchema),
        defaultValues: { current_password: '', new_password: '', confirm_password: '' },
    });

    const profileMutation = useMutation({
        mutationFn: async (values: ProfileValues) => (await api.patch('/auth/me', values)).data,
        onSuccess: (data) => {
            setUser(data);
            setProfileSaved(true);
            setTimeout(() => setProfileSaved(false), 3000);
        },
    });

    const passwordMutation = useMutation({
        mutationFn: async (values: PasswordValues) =>
            api.post('/auth/me/password', {
                current_password: values.current_password,
                new_password: values.new_password,
            }),
        onSuccess: () => {
            passwordForm.reset();
            setPasswordSaved(true);
            setTimeout(() => setPasswordSaved(false), 3000);
        },
    });

    const initials = user?.full_name
        ?.split(' ')
        .map((n) => n[0])
        .slice(0, 2)
        .join('')
        .toUpperCase() ?? 'U';

    return (
        <div className="space-y-6 max-w-2xl">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Meu Perfil</h1>
                <p className="text-muted-foreground mt-1">Gerencie suas informações pessoais e senha</p>
            </div>

            {/* Avatar */}
            <Card>
                <CardContent className="flex items-center gap-4 pt-6">
                    <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary text-white text-xl font-bold">
                        {initials}
                    </div>
                    <div>
                        <p className="font-semibold text-lg">{user?.full_name}</p>
                        <p className="text-sm text-muted-foreground">{user?.email}</p>
                    </div>
                </CardContent>
            </Card>

            {/* Profile info */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <User className="h-5 w-5" />
                        Informações Pessoais
                    </CardTitle>
                    <CardDescription>Atualize seu nome e telefone de contato.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Form {...profileForm}>
                        <form
                            onSubmit={profileForm.handleSubmit((v) => profileMutation.mutate(v))}
                            className="space-y-4"
                        >
                            <FormField
                                control={profileForm.control}
                                name="full_name"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Nome Completo</FormLabel>
                                        <FormControl>
                                            <Input {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={profileForm.control}
                                name="phone"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Telefone</FormLabel>
                                        <FormControl>
                                            <Input placeholder="(11) 99999-9999" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            {profileMutation.isError && (
                                <p className="text-sm text-red-500">Erro ao salvar. Tente novamente.</p>
                            )}
                            <Button type="submit" disabled={profileMutation.isPending}>
                                {profileMutation.isPending ? (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                ) : profileSaved ? (
                                    <Check className="mr-2 h-4 w-4 text-green-500" />
                                ) : (
                                    <Save className="mr-2 h-4 w-4" />
                                )}
                                {profileSaved ? 'Salvo!' : 'Salvar'}
                            </Button>
                        </form>
                    </Form>
                </CardContent>
            </Card>

            <Separator />

            {/* Change password */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Lock className="h-5 w-5" />
                        Alterar Senha
                    </CardTitle>
                    <CardDescription>Use uma senha forte com ao menos 6 caracteres.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Form {...passwordForm}>
                        <form
                            onSubmit={passwordForm.handleSubmit((v) => passwordMutation.mutate(v))}
                            className="space-y-4"
                        >
                            <FormField
                                control={passwordForm.control}
                                name="current_password"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Senha Atual</FormLabel>
                                        <FormControl>
                                            <Input type="password" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <div className="grid grid-cols-2 gap-4">
                                <FormField
                                    control={passwordForm.control}
                                    name="new_password"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Nova Senha</FormLabel>
                                            <FormControl>
                                                <Input type="password" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={passwordForm.control}
                                    name="confirm_password"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Confirmar Nova Senha</FormLabel>
                                            <FormControl>
                                                <Input type="password" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                            </div>
                            {passwordMutation.isError && (
                                <p className="text-sm text-red-500">Senha atual incorreta. Tente novamente.</p>
                            )}
                            <Button type="submit" variant="outline" disabled={passwordMutation.isPending}>
                                {passwordMutation.isPending ? (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                ) : passwordSaved ? (
                                    <Check className="mr-2 h-4 w-4 text-green-500" />
                                ) : (
                                    <Lock className="mr-2 h-4 w-4" />
                                )}
                                {passwordSaved ? 'Senha alterada!' : 'Alterar Senha'}
                            </Button>
                        </form>
                    </Form>
                </CardContent>
            </Card>
        </div>
    );
}

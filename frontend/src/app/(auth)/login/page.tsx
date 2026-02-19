'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { PawPrint, Loader2 } from 'lucide-react';
import api from '@/lib/axios';
import { useAuthStore } from '@/stores/useAuthStore';

import { Button } from '@/components/ui/button';
import {
    Form,
    FormControl,
    FormField,
    FormItem,
    FormLabel,
    FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
} from '@/components/ui/card';

const formSchema = z.object({
    username: z.string().email({
        message: 'Email inválido.',
    }),
    password: z.string().min(1, {
        message: 'A senha é obrigatória.',
    }),
});

export default function LoginPage() {
    const router = useRouter();
    const setAuth = useAuthStore((state) => state.setAuth);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    const form = useForm<z.infer<typeof formSchema>>({
        resolver: zodResolver(formSchema),
        defaultValues: {
            username: '',
            password: '',
        },
    });

    async function onSubmit(values: z.infer<typeof formSchema>) {
        setIsLoading(true);
        setError('');

        try {
            // 1. Obter Token
            const formData = new FormData();
            formData.append('username', values.username);
            formData.append('password', values.password);

            const tokenResponse = await api.post('/auth/login', formData, {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            });

            const { access_token } = tokenResponse.data;
            localStorage.setItem('token', access_token);

            // 2. Obter Dados do Usuário
            const userResponse = await api.get('/auth/me', {
                headers: { Authorization: `Bearer ${access_token}` }
            });

            setAuth(access_token, userResponse.data);
            router.push('/pets');
        } catch (err: any) {
            console.error(err);
            setError('Credenciais inválidas ou erro no servidor.');
        } finally {
            setIsLoading(false);
        }
    }

    return (
        <div className="flex min-h-screen items-center justify-center bg-gradient-to-b from-purple-50 to-white dark:from-gray-950 dark:to-gray-900 px-4 py-12 sm:px-6 lg:px-8">
            <Card className="w-full max-w-md">
                <CardHeader className="space-y-1">
                    <div className="flex justify-center mb-4">
                        <div className="rounded-full bg-primary/10 p-3">
                            <PawPrint className="h-8 w-8 text-primary" />
                        </div>
                    </div>
                    <CardTitle className="text-2xl font-bold text-center">Entrar no PetID</CardTitle>
                    <CardDescription className="text-center">
                        Digite seu email e senha para acessar o sistema
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Form {...form}>
                        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                            <FormField
                                control={form.control}
                                name="username"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Email</FormLabel>
                                        <FormControl>
                                            <Input placeholder="admin@example.com" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="password"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Senha</FormLabel>
                                        <FormControl>
                                            <Input type="password" placeholder="******" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />

                            {error && (
                                <div className="p-3 text-sm text-red-500 bg-red-50 rounded-md">
                                    {error}
                                </div>
                            )}

                            <Button type="submit" className="w-full" disabled={isLoading}>
                                {isLoading ? (
                                    <>
                                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                        Entrando...
                                    </>
                                ) : (
                                    'Entrar'
                                )}
                            </Button>
                        </form>
                    </Form>
                </CardContent>
                <CardFooter className="flex flex-col gap-2">
                    <p className="text-sm text-muted-foreground text-center">
                        Não tem uma conta?{' '}
                        <Link href="/register" className="text-primary hover:underline font-medium">
                            Cadastre-se
                        </Link>
                    </p>
                    <p className="text-xs text-muted-foreground text-center">
                        Esqueceu a senha? Contate o administrador.
                    </p>
                </CardFooter>
            </Card>
        </div>
    );
}

'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { PawPrint, Loader2, ArrowLeft } from 'lucide-react';
import api from '@/lib/axios';

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
    full_name: z.string().min(2, {
        message: 'Nome deve ter pelo menos 2 caracteres.',
    }),
    email: z.string().email({
        message: 'Email inválido.',
    }),
    phone: z.string().optional(),
    password: z.string().min(6, {
        message: 'A senha deve ter pelo menos 6 caracteres.',
    }),
    confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
    message: 'As senhas não coincidem.',
    path: ['confirmPassword'],
});

export default function RegisterPage() {
    const router = useRouter();
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const form = useForm<z.infer<typeof formSchema>>({
        resolver: zodResolver(formSchema),
        defaultValues: {
            full_name: '',
            email: '',
            phone: '',
            password: '',
            confirmPassword: '',
        },
    });

    async function onSubmit(values: z.infer<typeof formSchema>) {
        setIsLoading(true);
        setError('');

        try {
            await api.post('/auth/register', {
                full_name: values.full_name,
                email: values.email,
                phone: values.phone || null,
                password: values.password,
            });

            setSuccess(true);
            setTimeout(() => {
                router.push('/login');
            }, 2000);
        } catch (err: unknown) {
            const error = err as { response?: { data?: { detail?: string } } };
            if (error.response?.data?.detail === 'Email já cadastrado') {
                setError('Este email já está cadastrado. Tente fazer login.');
            } else {
                setError('Erro ao criar conta. Tente novamente.');
            }
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
                    <CardTitle className="text-2xl font-bold text-center">Criar Conta</CardTitle>
                    <CardDescription className="text-center">
                        Cadastre-se para gerenciar seus pets no PetID
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {success ? (
                        <div className="text-center py-6">
                            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-green-100 text-green-600 mb-4">
                                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                            </div>
                            <h3 className="font-semibold text-lg mb-2">Conta criada!</h3>
                            <p className="text-sm text-muted-foreground">
                                Redirecionando para o login...
                            </p>
                        </div>
                    ) : (
                        <Form {...form}>
                            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                                <FormField
                                    control={form.control}
                                    name="full_name"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Nome Completo</FormLabel>
                                            <FormControl>
                                                <Input placeholder="João Silva" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="email"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Email</FormLabel>
                                            <FormControl>
                                                <Input type="email" placeholder="joao@exemplo.com" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <FormField
                                    control={form.control}
                                    name="phone"
                                    render={({ field }) => (
                                        <FormItem>
                                            <FormLabel>Telefone (opcional)</FormLabel>
                                            <FormControl>
                                                <Input placeholder="(11) 99999-9999" {...field} />
                                            </FormControl>
                                            <FormMessage />
                                        </FormItem>
                                    )}
                                />
                                <div className="grid grid-cols-2 gap-4">
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
                                    <FormField
                                        control={form.control}
                                        name="confirmPassword"
                                        render={({ field }) => (
                                            <FormItem>
                                                <FormLabel>Confirmar</FormLabel>
                                                <FormControl>
                                                    <Input type="password" placeholder="******" {...field} />
                                                </FormControl>
                                                <FormMessage />
                                            </FormItem>
                                        )}
                                    />
                                </div>

                                {error && (
                                    <div className="p-3 text-sm text-red-500 bg-red-50 dark:bg-red-950 rounded-md">
                                        {error}
                                    </div>
                                )}

                                <Button type="submit" className="w-full" disabled={isLoading}>
                                    {isLoading ? (
                                        <>
                                            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                            Criando conta...
                                        </>
                                    ) : (
                                        'Criar Conta'
                                    )}
                                </Button>
                            </form>
                        </Form>
                    )}
                </CardContent>
                <CardFooter className="flex flex-col gap-2">
                    <p className="text-sm text-muted-foreground text-center">
                        Já tem uma conta?{' '}
                        <Link href="/login" className="text-primary hover:underline font-medium">
                            Faça login
                        </Link>
                    </p>
                    <Link href="/" className="text-sm text-muted-foreground hover:text-primary flex items-center gap-1">
                        <ArrowLeft className="h-3 w-3" />
                        Voltar ao início
                    </Link>
                </CardFooter>
            </Card>
        </div>
    );
}

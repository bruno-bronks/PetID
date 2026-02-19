'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuthStore } from '@/stores/useAuthStore';
import { PawPrint, ScanFace, QrCode, FileText, Syringe, Pill, Stethoscope, ArrowRight, AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function Home() {
    const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    // Para evitar hydration mismatch, só verifica auth após montar
    const isLoggedIn = mounted && isAuthenticated();

    return (
        <div className="min-h-screen bg-gradient-to-b from-purple-50 via-white to-white dark:from-gray-950 dark:via-gray-900 dark:to-gray-900">
            {/* Header */}
            <header className="border-b bg-white/80 dark:bg-gray-950/80 backdrop-blur-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 h-16 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-2 font-bold text-xl">
                        <PawPrint className="h-7 w-7 text-primary" />
                        <span>PetID</span>
                    </Link>
                    <div className="flex items-center gap-3">
                        {isLoggedIn ? (
                            <Link href="/pets">
                                <Button size="sm">Meus Pets</Button>
                            </Link>
                        ) : (
                            <Link href="/login">
                                <Button size="sm">Entrar</Button>
                            </Link>
                        )}
                    </div>
                </div>
            </header>

            {/* Hero */}
            <section className="container mx-auto px-4 py-20 text-center">
                <div className="inline-flex items-center gap-2 rounded-full bg-primary/10 px-4 py-1.5 text-sm text-primary mb-6">
                    <PawPrint className="h-4 w-4" />
                    Gestão completa para seu pet
                </div>
                <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight max-w-3xl mx-auto">
                    Tudo sobre seu pet em um só lugar
                </h1>
                <p className="mt-6 text-xl text-muted-foreground max-w-2xl mx-auto">
                    PetID é a plataforma completa para gerenciar a saúde, documentos e identificação do seu pet.
                    Prontuário digital, vacinas, medicamentos e identificação biométrica.
                </p>
                <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
                    <Link href={isLoggedIn ? "/pets" : "/login"}>
                        <Button size="lg" className="text-lg px-8">
                            Começar agora
                            <ArrowRight className="ml-2 h-5 w-5" />
                        </Button>
                    </Link>
                    <Link href="/scan">
                        <Button size="lg" variant="outline" className="text-lg px-8">
                            <ScanFace className="mr-2 h-5 w-5" />
                            Identificar Pet
                        </Button>
                    </Link>
                </div>
                <div className="mt-6">
                    <Link href="/lost" className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-orange-500 transition-colors">
                        <AlertTriangle className="h-4 w-4" />
                        Ver pets perdidos na sua região
                    </Link>
                </div>
            </section>

            {/* Features */}
            <section className="bg-gray-50 dark:bg-gray-900 py-16">
                <div className="container mx-auto px-4">
                    <h2 className="text-2xl font-bold text-center mb-4">Recursos</h2>
                    <p className="text-center text-muted-foreground mb-12 max-w-xl mx-auto">
                        Gerencie todas as informações do seu pet de forma organizada e acessível
                    </p>
                    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 max-w-5xl mx-auto">
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <Stethoscope className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">Prontuário Digital</h3>
                            <p className="text-sm text-muted-foreground">
                                Histórico completo de consultas, exames e cirurgias em um só lugar
                            </p>
                        </div>
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <Syringe className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">Carteira de Vacinas</h3>
                            <p className="text-sm text-muted-foreground">
                                Controle de vacinas aplicadas e lembretes de próximas doses
                            </p>
                        </div>
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <Pill className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">Medicamentos</h3>
                            <p className="text-sm text-muted-foreground">
                                Acompanhe tratamentos ativos, dosagens e frequências
                            </p>
                        </div>
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <FileText className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">Documentos</h3>
                            <p className="text-sm text-muted-foreground">
                                Armazene RG animal, laudos, receitas e resultados de exames
                            </p>
                        </div>
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <QrCode className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">QR Code</h3>
                            <p className="text-sm text-muted-foreground">
                                Gere QR codes para coleiras com acesso rápido ao perfil do pet
                            </p>
                        </div>
                        <div className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm">
                            <ScanFace className="h-8 w-8 text-primary mb-4" />
                            <h3 className="font-semibold mb-2">Biometria Nasal</h3>
                            <p className="text-sm text-muted-foreground">
                                Identifique o pet pelo focinho e acesse suas informações
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            {/* Biometry Section */}
            <section className="container mx-auto px-4 py-16">
                <div className="max-w-4xl mx-auto grid md:grid-cols-2 gap-12 items-center">
                    <div>
                        <h2 className="text-2xl font-bold mb-4">Identificação por Focinho</h2>
                        <p className="text-muted-foreground mb-4">
                            Cada pet tem um focinho único, como uma impressão digital.
                            Cadastre a biometria nasal do seu pet e permita que ele seja
                            identificado apenas com uma foto.
                        </p>
                        <ul className="space-y-2 text-sm text-muted-foreground mb-6">
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Escaneie o focinho e veja informações do pet
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Útil para clínicas e pet shops identificarem animais
                            </li>
                            <li className="flex items-center gap-2">
                                <span className="text-green-500">✓</span>
                                Ajuda a encontrar o dono de pets perdidos
                            </li>
                        </ul>
                        <Link href="/scan">
                            <Button variant="outline">
                                <ScanFace className="mr-2 h-4 w-4" />
                                Testar identificação
                            </Button>
                        </Link>
                    </div>
                    <div className="bg-gradient-to-br from-purple-100 to-violet-100 dark:from-purple-900/30 dark:to-violet-900/30 rounded-2xl p-8 text-center">
                        <ScanFace className="h-24 w-24 mx-auto text-primary/60 mb-4" />
                        <p className="text-sm text-muted-foreground">
                            Tire uma foto do focinho → Sistema compara na base → Retorna dados do pet
                        </p>
                    </div>
                </div>
            </section>

            {/* CTA */}
            <section className="bg-primary text-primary-foreground py-16">
                <div className="container mx-auto px-4 text-center">
                    <h2 className="text-3xl font-bold mb-4">Comece a usar o PetID</h2>
                    <p className="mb-8 max-w-xl mx-auto opacity-90">
                        Cadastre seu pet gratuitamente e tenha todas as informações
                        de saúde e identificação organizadas.
                    </p>
                    <Link href={isLoggedIn ? "/pets/new" : "/login"}>
                        <Button size="lg" variant="secondary">
                            Cadastrar meu pet
                            <ArrowRight className="ml-2 h-5 w-5" />
                        </Button>
                    </Link>
                </div>
            </section>

            {/* Footer */}
            <footer className="border-t py-8">
                <div className="container mx-auto px-4 text-center text-sm text-muted-foreground">
                    <div className="flex items-center justify-center gap-2 mb-2">
                        <PawPrint className="h-4 w-4" />
                        <span className="font-medium">PetID</span>
                    </div>
                    <p>Gestão completa para seu pet</p>
                </div>
            </footer>
        </div>
    );
}

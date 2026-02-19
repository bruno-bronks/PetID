'use client';

import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Bell, Shield, Globe, Database, Moon, Sun, Monitor, ChevronRight, Check, Download, Loader2 } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import api from '@/lib/axios';
import { downloadCSV, formatPetsForExport } from '@/lib/export';

const themeOptions = [
    { value: 'light', label: 'Claro', icon: Sun },
    { value: 'dark', label: 'Escuro', icon: Moon },
    { value: 'system', label: 'Sistema', icon: Monitor },
];

interface Pet {
    id: number;
    name: string;
    species: string;
    breed: string;
    sex: string;
    birth_date: string | null;
    color: string | null;
    microchip: string | null;
}

export default function SettingsPage() {
    const { theme, setTheme } = useTheme();
    const [mounted, setMounted] = useState(false);
    const [exporting, setExporting] = useState(false);

    const { data: pets } = useQuery<Pet[]>({
        queryKey: ['pets'],
        queryFn: async () => (await api.get('/pets/')).data,
    });

    useEffect(() => {
        setMounted(true);
    }, []);

    const handleExportPets = () => {
        if (!pets || pets.length === 0) return;
        setExporting(true);
        try {
            const exportData = formatPetsForExport(pets);
            downloadCSV(exportData, 'meus_pets');
        } finally {
            setExporting(false);
        }
    };

    return (
        <div className="space-y-6 max-w-2xl">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Configurações</h1>
                <p className="text-muted-foreground mt-1">Gerencie as preferências do sistema</p>
            </div>

            {/* Conta */}
            <Card>
                <CardHeader className="pb-3">
                    <CardTitle className="text-base">Conta</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                    <Link
                        href="/profile"
                        className="flex items-center gap-4 rounded-lg p-3 hover:bg-muted transition-colors"
                    >
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10">
                            <Shield className="h-4 w-4 text-primary" />
                        </div>
                        <div className="flex-1">
                            <p className="text-sm font-medium">Perfil & Senha</p>
                            <p className="text-xs text-muted-foreground">Edite seu nome, telefone e senha de acesso</p>
                        </div>
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                    </Link>
                </CardContent>
            </Card>

            {/* Aparência */}
            <Card>
                <CardHeader className="pb-3">
                    <CardTitle className="text-base">Aparência</CardTitle>
                    <CardDescription>Escolha o tema do sistema</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="grid grid-cols-3 gap-3">
                        {themeOptions.map((option) => {
                            const Icon = option.icon;
                            const isActive = mounted && theme === option.value;
                            return (
                                <Button
                                    key={option.value}
                                    variant={isActive ? 'default' : 'outline'}
                                    className="h-auto flex-col gap-2 py-4 relative"
                                    onClick={() => setTheme(option.value)}
                                >
                                    <Icon className="h-5 w-5" />
                                    <span className="text-xs">{option.label}</span>
                                    {isActive && (
                                        <Check className="h-3 w-3 absolute top-2 right-2" />
                                    )}
                                </Button>
                            );
                        })}
                    </div>
                </CardContent>
            </Card>

            {/* Sistema */}
            <Card>
                <CardHeader className="pb-3">
                    <CardTitle className="text-base">Sistema</CardTitle>
                </CardHeader>
                <CardContent className="space-y-1 pt-0">
                    <div className="flex items-center gap-4 rounded-lg p-3 opacity-50 cursor-not-allowed">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10">
                            <Bell className="h-4 w-4 text-primary" />
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <p className="text-sm font-medium">Notificações</p>
                                <Badge variant="secondary" className="text-xs">Em breve</Badge>
                            </div>
                            <p className="text-xs text-muted-foreground">Alertas de vacinas vencidas e pets perdidos</p>
                        </div>
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                    </div>
                    <Separator />
                    <div className="flex items-center gap-4 rounded-lg p-3 opacity-50 cursor-not-allowed">
                        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10">
                            <Globe className="h-4 w-4 text-primary" />
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <p className="text-sm font-medium">Idioma & Região</p>
                                <Badge variant="secondary" className="text-xs">Em breve</Badge>
                            </div>
                            <p className="text-xs text-muted-foreground">Idioma do sistema e formato de datas</p>
                        </div>
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                    </div>
                </CardContent>
            </Card>

            {/* Dados */}
            <Card>
                <CardHeader className="pb-3">
                    <CardTitle className="text-base">Dados</CardTitle>
                    <CardDescription>Exporte os dados dos seus pets</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                    <div className="flex items-center justify-between gap-4 rounded-lg border p-4">
                        <div className="flex items-center gap-3">
                            <Database className="h-5 w-5 text-muted-foreground" />
                            <div>
                                <p className="text-sm font-medium">Exportar Pets</p>
                                <p className="text-xs text-muted-foreground">
                                    {pets?.length ?? 0} pets cadastrados
                                </p>
                            </div>
                        </div>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={handleExportPets}
                            disabled={!pets?.length || exporting}
                        >
                            {exporting ? (
                                <Loader2 className="h-4 w-4 animate-spin" />
                            ) : (
                                <>
                                    <Download className="h-4 w-4 mr-2" />
                                    CSV
                                </>
                            )}
                        </Button>
                    </div>
                    <p className="text-xs text-muted-foreground">
                        O arquivo CSV pode ser aberto no Excel, Google Sheets ou qualquer editor de planilhas.
                    </p>
                </CardContent>
            </Card>

            {/* Sobre */}
            <Card>
                <CardHeader className="pb-3">
                    <CardTitle className="text-base">Sobre o PetID</CardTitle>
                    <CardDescription className="text-xs space-y-1">
                        <span className="block">Versão 1.0.0</span>
                        <span className="block">Sistema de gestão de pets com identificação por biometria nasal</span>
                    </CardDescription>
                </CardHeader>
            </Card>
        </div>
    );
}

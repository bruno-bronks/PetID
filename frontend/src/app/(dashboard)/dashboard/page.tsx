'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { toast } from 'sonner';
import {
    Loader2, PawPrint, Syringe, Activity, AlertCircle,
    TrendingUp, CalendarDays, Stethoscope, Check, Pill
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
    PieChart, Pie, Cell, ResponsiveContainer,
} from 'recharts';

interface Pet { id: number; name: string; species: string; breed: string; }
interface VaccineReminder { id: number; vaccine_name: string; scheduled_date: string; is_completed: boolean; pet_id: number; pet_name?: string; }
interface UpcomingVaccinesResponse { upcoming: VaccineReminder[]; overdue: VaccineReminder[]; total_pending: number; }
interface Medication { id: number; name: string; dosage: string; frequency: string; pet_id: number; pet_name: string; is_active: boolean; }

const SPECIES_COLORS: Record<string, string> = {
    dog: '#f59e0b',
    cat: '#8b5cf6',
    other: '#6b7280',
};
const SPECIES_LABELS: Record<string, string> = { dog: 'Cão', cat: 'Gato', other: 'Outro' };

export default function DashboardPage() {
    const [_tab] = useState('overview');

    const queryClient = useQueryClient();

    const { data: pets, isLoading: petsLoading } = useQuery<Pet[]>({
        queryKey: ['pets'],
        queryFn: async () => (await api.get('/pets/')).data,
    });

    const { data: vaccineData, isLoading: vaccinesLoading } = useQuery<UpcomingVaccinesResponse>({
        queryKey: ['vaccines', 'upcoming'],
        queryFn: async () => (await api.get('/vaccines/upcoming?days_ahead=30')).data,
    });

    const { data: medications, isLoading: medsLoading } = useQuery<Medication[]>({
        queryKey: ['medications', 'active'],
        queryFn: async () => (await api.get('/medications/active')).data,
    });

    const completeVaccine = useMutation({
        mutationFn: async (id: number) => {
            return api.post(`/vaccines/${id}/complete`, {
                completed_date: new Date().toISOString().split('T')[0],
            });
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['vaccines'] });
            toast.success('Vacina marcada como aplicada!');
        },
        onError: () => {
            toast.error('Erro ao marcar vacina como aplicada.');
        },
    });

    const isLoading = petsLoading || vaccinesLoading || medsLoading;

    // Derived data for charts
    const speciesGroups = pets?.reduce<Record<string, number>>((acc, pet) => {
        acc[pet.species] = (acc[pet.species] ?? 0) + 1;
        return acc;
    }, {}) ?? {};

    const speciesPieData = Object.entries(speciesGroups).map(([key, value]) => ({
        name: SPECIES_LABELS[key] ?? key,
        value,
        color: SPECIES_COLORS[key] ?? '#6b7280',
    }));

    // Upcoming vaccines by month (next 30 days grouped by week)
    const vaccinesByWeek = (vaccineData?.upcoming ?? []).reduce<Record<string, number>>((acc, v) => {
        const date = new Date(v.scheduled_date);
        const week = `Sem ${Math.ceil(date.getDate() / 7)}`;
        acc[week] = (acc[week] ?? 0) + 1;
        return acc;
    }, {});
    const vaccineBarData = Object.entries(vaccinesByWeek).map(([week, total]) => ({ week, total }));

    const statCards = [
        { title: 'Total de Pets', value: pets?.length ?? '-', icon: PawPrint, color: 'text-blue-500', bg: 'bg-blue-50' },
        { title: 'Vacinas (30d)', value: vaccineData?.upcoming?.length ?? '-', icon: Syringe, color: 'text-green-500', bg: 'bg-green-50' },
        { title: 'Vacinas Vencidas', value: vaccineData?.overdue?.length ?? '-', icon: AlertCircle, color: 'text-red-500', bg: 'bg-red-50' },
        { title: 'Total Pendente', value: vaccineData?.total_pending ?? '-', icon: Activity, color: 'text-orange-500', bg: 'bg-orange-50' },
    ];

    if (isLoading) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
                <p className="text-muted-foreground mt-1">Visão geral do sistema PetID</p>
            </div>

            {/* Stats Cards */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                {statCards.map((stat) => (
                    <Card key={stat.title}>
                        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                            <CardTitle className="text-sm font-medium text-muted-foreground">{stat.title}</CardTitle>
                            <div className={`rounded-full p-2 ${stat.bg}`}>
                                <stat.icon className={`h-4 w-4 ${stat.color}`} />
                            </div>
                        </CardHeader>
                        <CardContent>
                            <div className="text-3xl font-bold">{stat.value}</div>
                        </CardContent>
                    </Card>
                ))}
            </div>

            {/* Charts row */}
            <div className="grid gap-6 md:grid-cols-2">
                {/* Species pie chart */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-2">
                            <TrendingUp className="h-4 w-4 text-muted-foreground" />
                            <CardTitle className="text-sm">Pets por Espécie</CardTitle>
                        </div>
                    </CardHeader>
                    <CardContent>
                        {speciesPieData.length === 0 ? (
                            <p className="text-center text-sm text-muted-foreground py-8">Nenhum pet cadastrado.</p>
                        ) : (
                            <ResponsiveContainer width="100%" height={220}>
                                <PieChart>
                                    <Pie
                                        data={speciesPieData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={55}
                                        outerRadius={90}
                                        paddingAngle={3}
                                        dataKey="value"
                                        label={({ name, percent }: { name?: string; percent?: number }) => `${name ?? ''} ${((percent ?? 0) * 100).toFixed(0)}%`}
                                        labelLine={false}
                                    >
                                        {speciesPieData.map((entry, index) => (
                                            <Cell key={index} fill={entry.color} />
                                        ))}
                                    </Pie>
                                    <Tooltip formatter={(value) => [`${value} pets`, '']} />
                                </PieChart>
                            </ResponsiveContainer>
                        )}
                    </CardContent>
                </Card>

                {/* Vaccines bar chart */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-2">
                            <CalendarDays className="h-4 w-4 text-muted-foreground" />
                            <CardTitle className="text-sm">Vacinas Próximas (por semana)</CardTitle>
                        </div>
                    </CardHeader>
                    <CardContent>
                        {vaccineBarData.length === 0 ? (
                            <p className="text-center text-sm text-muted-foreground py-8">
                                {vaccineData?.overdue?.length === 0
                                    ? '✅ Nenhuma vacina pendente nos próximos 30 dias.'
                                    : 'Nenhuma vacina agendada para os próximos 30 dias.'}
                            </p>
                        ) : (
                            <ResponsiveContainer width="100%" height={220}>
                                <BarChart data={vaccineBarData} margin={{ top: 5, right: 10, left: -10, bottom: 5 }}>
                                    <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                                    <XAxis dataKey="week" tick={{ fontSize: 12 }} />
                                    <YAxis tick={{ fontSize: 12 }} allowDecimals={false} />
                                    <Tooltip />
                                    <Bar dataKey="total" name="Vacinas" fill="#22c55e" radius={[4, 4, 0, 0]} />
                                </BarChart>
                            </ResponsiveContainer>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Bottom row: Pets list + vaccine alerts */}
            <div className="grid gap-6 md:grid-cols-2">
                {/* Pets */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Stethoscope className="h-4 w-4 text-muted-foreground" />
                            <CardTitle>Seus Pets</CardTitle>
                        </div>
                        <Button asChild variant="outline" size="sm">
                            <Link href="/pets">Ver todos</Link>
                        </Button>
                    </CardHeader>
                    <CardContent>
                        {pets?.length === 0 ? (
                            <p className="text-sm text-muted-foreground text-center py-6">
                                Nenhum pet cadastrado.{' '}
                                <Link href="/pets/new" className="text-primary underline">Adicionar agora</Link>
                            </p>
                        ) : (
                            <div className="space-y-2">
                                {pets?.slice(0, 5).map((pet) => (
                                    <Link
                                        key={pet.id}
                                        href={`/pets/${pet.id}`}
                                        className="flex items-center gap-3 rounded-lg p-2 hover:bg-muted transition-colors"
                                    >
                                        <div
                                            className="flex h-8 w-8 items-center justify-center rounded-full text-sm"
                                            style={{ background: (SPECIES_COLORS[pet.species] ?? '#6b7280') + '22' }}
                                        >
                                            {pet.species === 'dog' ? '🐶' : pet.species === 'cat' ? '🐱' : '🐾'}
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <p className="font-medium text-sm truncate">{pet.name}</p>
                                            <p className="text-xs text-muted-foreground capitalize">
                                                {SPECIES_LABELS[pet.species] ?? pet.species}{pet.breed ? ` • ${pet.breed}` : ''}
                                            </p>
                                        </div>
                                    </Link>
                                ))}
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Vaccine alerts */}
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between">
                        <div className="flex items-center gap-2">
                            <Syringe className="h-4 w-4 text-muted-foreground" />
                            <CardTitle>Alertas de Vacinas</CardTitle>
                        </div>
                        {(vaccineData?.overdue?.length ?? 0) > 0 && (
                            <Badge variant="destructive">{vaccineData?.overdue?.length} vencidas</Badge>
                        )}
                    </CardHeader>
                    <CardContent>
                        {(!vaccineData?.overdue?.length && !vaccineData?.upcoming?.length) ? (
                            <p className="text-sm text-muted-foreground text-center py-6">✅ Todas as vacinas estão em dia!</p>
                        ) : (
                            <div className="space-y-3">
                                {vaccineData?.overdue?.slice(0, 3).map((v) => (
                                    <div key={v.id} className="flex items-center gap-3 rounded-xl border border-red-100 bg-red-50 p-2.5">
                                        <AlertCircle className="h-5 w-5 text-red-500 shrink-0" />
                                        <div className="flex-1 min-w-0">
                                            <p className="text-sm font-bold text-red-700 truncate">{v.vaccine_name}</p>
                                            <p className="text-xs text-red-600">Venceu em {new Date(v.scheduled_date).toLocaleDateString('pt-BR')}</p>
                                        </div>
                                        <Button
                                            size="icon"
                                            variant="ghost"
                                            className="h-8 w-8 text-red-600 hover:bg-red-100 shrink-0"
                                            onClick={() => completeVaccine.mutate(v.id)}
                                            disabled={completeVaccine.isPending}
                                        >
                                            <Check className="h-4 w-4" />
                                        </Button>
                                    </div>
                                ))}
                                {vaccineData?.upcoming?.slice(0, 3).map((v) => (
                                    <div key={v.id} className="flex items-center gap-3 rounded-xl border border-green-100 bg-green-50 p-2.5">
                                        <Syringe className="h-5 w-5 text-green-600 shrink-0" />
                                        <div className="flex-1 min-w-0">
                                            <p className="text-sm font-bold text-green-700 truncate">{v.vaccine_name}</p>
                                            <p className="text-xs text-green-600">Prevista para {new Date(v.scheduled_date).toLocaleDateString('pt-BR')}</p>
                                        </div>
                                        <Button
                                            size="icon"
                                            variant="ghost"
                                            className="h-8 w-8 text-green-600 hover:bg-green-100 shrink-0"
                                            onClick={() => completeVaccine.mutate(v.id)}
                                            disabled={completeVaccine.isPending}
                                        >
                                            <Check className="h-4 w-4" />
                                        </Button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Row 3: Administering meds */}
            <div className="grid gap-6">
                <Card>
                    <CardHeader>
                        <div className="flex items-center gap-2">
                            <Pill className="h-4 w-4 text-muted-foreground" />
                            <CardTitle>Medicamentos em Uso</CardTitle>
                        </div>
                    </CardHeader>
                    <CardContent>
                        {!medications || medications.length === 0 ? (
                            <p className="text-sm text-muted-foreground text-center py-6">Nenhum medicamento ativo registrado.</p>
                        ) : (
                            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                                {medications.map((m) => (
                                    <div key={m.id} className="flex items-center gap-4 rounded-xl border p-4 bg-muted/30">
                                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-purple-100 shrink-0">
                                            <Pill className="h-5 w-5 text-purple-600" />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center justify-between">
                                                <p className="font-bold text-sm text-gray-900 truncate">{m.name}</p>
                                                <Badge variant="outline" className="text-[10px] py-0">{m.pet_name}</Badge>
                                            </div>
                                            <p className="text-xs text-muted-foreground truncate">{m.dosage} · {m.frequency}</p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}

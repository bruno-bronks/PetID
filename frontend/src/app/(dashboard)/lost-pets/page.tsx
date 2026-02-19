'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Loader2, PawPrint, MapPin, Phone, Calendar, CheckCircle2, AlertTriangle, Clock } from 'lucide-react';
import ReportLostPetModal from '@/components/lost-pets/ReportLostPetModal';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
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

interface LostPetReport {
    id: number;
    pet_id: number | null;
    pet_name: string | null;
    pet_species: string | null;
    pet_breed: string | null;
    report_type: 'lost' | 'found';
    status: 'active' | 'resolved';
    description: string;
    city: string | null;
    address: string | null;
    contact_phone: string | null;
    event_date: string;
    created_at: string;
    distance_km: number | null;
}

const typeConfig = {
    lost: { label: '🔴 Perdido', badgeVariant: 'destructive' as const },
    found: { label: '🟢 Encontrado', badgeVariant: 'default' as const },
};

export default function LostPetsPage() {
    const queryClient = useQueryClient();

    const { data: reports, isLoading } = useQuery<LostPetReport[]>({
        queryKey: ['lost-pets'],
        queryFn: async () => (await api.get('/public/lost-pets/my-reports')).data,
    });

    const resolveMutation = useMutation({
        mutationFn: async (reportId: number) =>
            api.patch(`/public/lost-pets/${reportId}/resolve`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lost-pets'] });
        },
    });

    const active = reports?.filter((r) => r.status === 'active') ?? [];
    const resolved = reports?.filter((r) => r.status === 'resolved') ?? [];

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Pets Perdidos</h1>
                    <p className="text-muted-foreground mt-1">
                        Gerencie seus reportes de pets perdidos e encontrados
                    </p>
                </div>
                <ReportLostPetModal />
            </div>

            {isLoading ? (
                <div className="flex h-64 items-center justify-center">
                    <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
                </div>
            ) : (
                <>
                    {/* Active reports */}
                    <div className="space-y-3">
                        <h2 className="text-lg font-semibold flex items-center gap-2">
                            <AlertTriangle className="h-5 w-5 text-red-500" />
                            Reportes Ativos
                            {active.length > 0 && (
                                <Badge variant="destructive">{active.length}</Badge>
                            )}
                        </h2>

                        {active.length === 0 ? (
                            <Card>
                                <CardContent className="flex flex-col items-center justify-center py-12 text-center gap-2">
                                    <PawPrint className="h-10 w-10 text-muted-foreground/40" />
                                    <p className="text-muted-foreground">Nenhum reporte ativo.</p>
                                    <p className="text-sm text-muted-foreground">
                                        Se um pet sumir, use o botão acima para alertar a comunidade.
                                    </p>
                                </CardContent>
                            </Card>
                        ) : (
                            <div className="grid gap-4 md:grid-cols-2">
                                {active.map((report) => (
                                    <ReportCard
                                        key={report.id}
                                        report={report}
                                        onResolve={() => resolveMutation.mutate(report.id)}
                                        resolving={resolveMutation.isPending}
                                    />
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Resolved reports */}
                    {resolved.length > 0 && (
                        <div className="space-y-3">
                            <h2 className="text-lg font-semibold flex items-center gap-2 text-muted-foreground">
                                <CheckCircle2 className="h-5 w-5 text-green-500" />
                                Resolvidos ({resolved.length})
                            </h2>
                            <div className="grid gap-4 md:grid-cols-2">
                                {resolved.map((report) => (
                                    <ReportCard key={report.id} report={report} resolved />
                                ))}
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    );
}

function ReportCard({
    report,
    onResolve,
    resolving,
    resolved,
}: {
    report: LostPetReport;
    onResolve?: () => void;
    resolving?: boolean;
    resolved?: boolean;
}) {
    const typeInfo = typeConfig[report.report_type];

    return (
        <Card className={resolved ? 'opacity-60' : ''}>
            <CardHeader className="pb-2">
                <div className="flex items-start justify-between gap-2">
                    <div>
                        <CardTitle className="text-base">
                            {report.pet_name ?? 'Pet desconhecido'}
                        </CardTitle>
                        {report.pet_species && (
                            <p className="text-xs text-muted-foreground capitalize">
                                {report.pet_species}{report.pet_breed ? ` • ${report.pet_breed}` : ''}
                            </p>
                        )}
                    </div>
                    <Badge variant={typeInfo.badgeVariant} className="shrink-0 text-xs">
                        {typeInfo.label}
                    </Badge>
                </div>
            </CardHeader>
            <CardContent className="space-y-2">
                <p className="text-sm text-muted-foreground line-clamp-2">{report.description}</p>

                <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                    {report.city && (
                        <span className="flex items-center gap-1">
                            <MapPin className="h-3.5 w-3.5" />
                            {report.city}
                        </span>
                    )}
                    {report.contact_phone && (
                        <span className="flex items-center gap-1">
                            <Phone className="h-3.5 w-3.5" />
                            {report.contact_phone}
                        </span>
                    )}
                    <span className="flex items-center gap-1">
                        <Calendar className="h-3.5 w-3.5" />
                        {new Date(report.event_date).toLocaleDateString('pt-BR')}
                    </span>
                    <span className="flex items-center gap-1">
                        <Clock className="h-3.5 w-3.5" />
                        Reportado em {new Date(report.created_at).toLocaleDateString('pt-BR')}
                    </span>
                </div>

                {!resolved && onResolve && (
                    <AlertDialog>
                        <AlertDialogTrigger asChild>
                            <Button variant="outline" size="sm" className="mt-1 w-full text-green-700 border-green-200 hover:bg-green-50">
                                <CheckCircle2 className="mr-1.5 h-4 w-4" />
                                Marcar como Encontrado
                            </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                            <AlertDialogHeader>
                                <AlertDialogTitle>Pet encontrado?</AlertDialogTitle>
                                <AlertDialogDescription>
                                    Isso vai marcar o reporte como resolvido e remover o alerta da comunidade.
                                </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                <AlertDialogAction onClick={onResolve} className="bg-green-600 hover:bg-green-700">
                                    {resolving ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Confirmar'}
                                </AlertDialogAction>
                            </AlertDialogFooter>
                        </AlertDialogContent>
                    </AlertDialog>
                )}
            </CardContent>
        </Card>
    );
}

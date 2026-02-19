'use client';

import { useQuery } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Loader2, Activity, LogIn, Key, Edit, Shield, PawPrint, FileText } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';

interface AuditLog {
    id: number;
    action: string;
    resource_type: string | null;
    resource_id: number | null;
    details: Record<string, unknown> | null;
    ip_address: string | null;
    created_at: string;
}

interface AuditLogListResponse {
    total: number;
    page: number;
    per_page: number;
    logs: AuditLog[];
}

const actionConfig: Record<string, { label: string; icon: React.ElementType; color: string }> = {
    login: { label: 'Login', icon: LogIn, color: 'bg-blue-100 text-blue-700' },
    logout: { label: 'Logout', icon: LogIn, color: 'bg-gray-100 text-gray-600' },
    password_change: { label: 'Senha alterada', icon: Key, color: 'bg-yellow-100 text-yellow-700' },
    user_update: { label: 'Perfil atualizado', icon: Edit, color: 'bg-green-100 text-green-700' },
    pet_create: { label: 'Pet cadastrado', icon: PawPrint, color: 'bg-purple-100 text-purple-700' },
    pet_update: { label: 'Pet atualizado', icon: PawPrint, color: 'bg-purple-100 text-purple-700' },
    pet_delete: { label: 'Pet removido', icon: PawPrint, color: 'bg-red-100 text-red-700' },
    document_upload: { label: 'Documento enviado', icon: FileText, color: 'bg-orange-100 text-orange-700' },
    token_refresh: { label: 'Token renovado', icon: Shield, color: 'bg-gray-100 text-gray-500' },
};

function getActionConfig(action: string) {
    return actionConfig[action.toLowerCase()] ?? { label: action, icon: Activity, color: 'bg-gray-100 text-gray-600' };
}

function formatRelativeTime(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'agora mesmo';
    if (diffMins < 60) return `há ${diffMins} min`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `há ${diffHours}h`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `há ${diffDays} dia${diffDays !== 1 ? 's' : ''}`;
    return date.toLocaleDateString('pt-BR');
}

export default function ActivityPage() {
    const { data, isLoading } = useQuery<AuditLogListResponse>({
        queryKey: ['my-activity'],
        queryFn: async () => (await api.get('/audit/my-activity?per_page=50')).data,
    });

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">Atividade</h1>
                <p className="text-muted-foreground mt-1">Histórico de ações realizadas na sua conta</p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle className="text-base flex items-center gap-2">
                        <Activity className="h-4 w-4" />
                        Últimas ações
                    </CardTitle>
                    <CardDescription>
                        {data?.total ? `${data.total} ações registradas` : 'Carregando...'}
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {isLoading ? (
                        <div className="flex justify-center py-12">
                            <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                        </div>
                    ) : !data?.logs?.length ? (
                        <p className="text-center text-sm text-muted-foreground py-12">
                            Nenhuma atividade registrada.
                        </p>
                    ) : (
                        <div className="relative">
                            {/* Timeline line */}
                            <div className="absolute left-5 top-3 bottom-3 w-px bg-border" />

                            <div className="space-y-4">
                                {data.logs.map((log) => {
                                    const cfg = getActionConfig(log.action);
                                    const Icon = cfg.icon;
                                    return (
                                        <div key={log.id} className="flex gap-4 pl-2">
                                            {/* Icon */}
                                            <div className={`relative z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${cfg.color}`}>
                                                <Icon className="h-3.5 w-3.5" />
                                            </div>
                                            {/* Content */}
                                            <div className="flex-1 pb-1">
                                                <div className="flex items-start justify-between gap-2">
                                                    <div>
                                                        <span className="font-medium text-sm">{cfg.label}</span>
                                                        {log.resource_type && log.resource_id && (
                                                            <Badge variant="outline" className="ml-2 text-xs">
                                                                {log.resource_type} #{log.resource_id}
                                                            </Badge>
                                                        )}
                                                        {log.details && Object.keys(log.details).length > 0 && (
                                                            <p className="text-xs text-muted-foreground mt-0.5">
                                                                {log.details.updated_fields
                                                                    ? `Campos: ${(log.details.updated_fields as string[]).join(', ')}`
                                                                    : JSON.stringify(log.details)}
                                                            </p>
                                                        )}
                                                    </div>
                                                    <div className="text-right shrink-0">
                                                        <p className="text-xs text-muted-foreground">{formatRelativeTime(log.created_at)}</p>
                                                        {log.ip_address && (
                                                            <p className="text-xs text-muted-foreground font-mono">{log.ip_address}</p>
                                                        )}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}

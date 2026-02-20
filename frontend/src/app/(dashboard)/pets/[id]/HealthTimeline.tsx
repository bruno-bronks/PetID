'use client';

import { Syringe, Pill, Stethoscope, ClipboardList, Activity, FileText, FlaskConical, Scissors } from 'lucide-react';

interface MedicalRecord {
    id: number;
    type: string;
    title: string;
    event_date: string;
    notes: string | null;
}

interface HealthTimelineProps {
    records: MedicalRecord[];
}

const typeConfig: Record<string, { icon: any; color: string; label: string; bg: string }> = {
    vaccine: { icon: Syringe, color: 'text-green-600', bg: 'bg-green-100', label: 'Vacina' },
    medication: { icon: Pill, color: 'text-purple-600', bg: 'bg-purple-100', label: 'Medicamento' },
    visit: { icon: Stethoscope, color: 'text-blue-600', bg: 'bg-blue-100', label: 'Consulta' },
    diagnosis: { icon: Activity, color: 'text-red-600', bg: 'bg-red-100', label: 'Diagnóstico' },
    exam: { icon: FlaskConical, color: 'text-amber-600', bg: 'bg-amber-100', label: 'Exame' },
    procedure: { icon: Scissors, color: 'text-indigo-600', bg: 'bg-indigo-100', label: 'Procedimento' },
    other: { icon: ClipboardList, color: 'text-gray-600', bg: 'bg-gray-100', label: 'Outro' },
};

export default function HealthTimeline({ records }: HealthTimelineProps) {
    if (!records || records.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center py-12 text-center">
                <div className="rounded-full bg-slate-50 p-4 mb-4">
                    <ClipboardList className="h-8 w-8 text-slate-300" />
                </div>
                <p className="text-slate-500 font-medium">Nenhum evento de saúde registrado ainda.</p>
                <p className="text-slate-400 text-sm max-w-xs">Tudo o que você registrar para seu pet aparecerá nesta linha do tempo histórica.</p>
            </div>
        );
    }

    // Records are already ordered by date from API (usually)
    // If not, we can sort them here
    const sortedRecords = [...records].sort((a, b) =>
        new Date(b.event_date).getTime() - new Date(a.event_date).getTime()
    );

    return (
        <div className="relative space-y-8 before:absolute before:inset-0 before:ml-5 before:-translate-x-px before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-200 before:to-transparent">
            {sortedRecords.map((record, index) => {
                const config = typeConfig[record.type] || typeConfig.other;
                const Icon = config.icon;
                const date = new Date(record.event_date);
                const year = date.getFullYear();
                const dayMonth = date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });

                return (
                    <div key={record.id} className="relative flex items-start group">
                        {/* Dot / Icon */}
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border-4 border-white bg-white shadow-sm z-10 transition-transform group-hover:scale-110">
                            <div className={`flex h-8 w-8 items-center justify-center rounded-full ${config.bg}`}>
                                <Icon className={`h-4 w-4 ${config.color}`} />
                            </div>
                        </div>

                        {/* Content */}
                        <div className="ml-6 pt-1">
                            <div className="flex items-center gap-2 mb-1">
                                <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                                    {dayMonth}, {year}
                                </span>
                                <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${config.bg} ${config.color} border-current opacity-70`}>
                                    {config.label}
                                </span>
                            </div>
                            <h3 className="font-bold text-slate-800 leading-tight group-hover:text-primary transition-colors">
                                {record.title}
                            </h3>
                            {record.notes && (
                                <p className="mt-1 text-sm text-slate-500 line-clamp-2">
                                    {record.notes}
                                </p>
                            )}
                        </div>
                    </div>
                );
            })}
        </div>
    );
}

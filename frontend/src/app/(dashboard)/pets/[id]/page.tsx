'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import api from '@/lib/axios';
import AddRecordModal from '@/components/pets/AddRecordModal';
import AddVetModal from '@/components/pets/AddVetModal';
import AddMedicationModal from '@/components/pets/AddMedicationModal';
import PetQRCodeModal from '@/components/pets/PetQRCodeModal';
import UploadDocumentModal from '@/components/pets/UploadDocumentModal';
import PetPhotoUpload from '@/components/pets/PetPhotoUpload';
import BiometryTab from '@/components/pets/BiometryTab';
import RecordAttachmentsButton from '@/components/pets/RecordAttachmentsButton';
import {
    ArrowLeft, Edit, Trash2, Loader2, PawPrint,
    Stethoscope, Syringe, Pill, Calendar, User as UserIcon,
    AlertTriangle, Phone, Mail, MapPin as MapPinIcon, FileText, ScanFace, CreditCard, History
} from 'lucide-react';
import HealthTimeline from './HealthTimeline';
import { toast } from 'sonner';

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
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';

interface Pet {
    id: number;
    name: string;
    species: string;
    breed: string;
    sex: string;
    birth_date: string | null;
    color: string | null;
    microchip: string | null;
    notes: string | null;
    photo_url: string | null;
    is_lost?: boolean;
}

interface MedicalRecord {
    id: number;
    type: string;
    title: string;
    event_date: string;
    veterinarian: string | null;
    clinic: string | null;
    notes: string | null;
}

interface Medication {
    id: number;
    name: string;
    dosage: string;
    frequency: string;
    start_date: string;
    end_date: string | null;
    is_active: boolean;
    prescribed_by: string | null;
}

interface Veterinarian {
    id: number;
    name: string;
    clinic_name: string | null;
    phone: string | null;
    email: string | null;
    address: string | null;
    specialty: string | null;
    notes: string | null;
}

const speciesLabel: Record<string, string> = {
    dog: '🐶 Cão',
    cat: '🐱 Gato',
    other: '🐾 Outro',
};

const sexLabel: Record<string, string> = {
    male: 'Macho',
    female: 'Fêmea',
    unknown: 'Não informado',
};

const recordTypeLabel: Record<string, { label: string; color: string }> = {
    consultation: { label: 'Consulta', color: 'bg-blue-100 text-blue-700' },
    vaccine: { label: 'Vacina', color: 'bg-green-100 text-green-700' },
    exam: { label: 'Exame', color: 'bg-purple-100 text-purple-700' },
    surgery: { label: 'Cirurgia', color: 'bg-red-100 text-red-700' },
    other: { label: 'Outro', color: 'bg-gray-100 text-gray-700' },
};

const docTypeLabel: Record<string, { label: string; color: string }> = {
    rg_animal: { label: 'RG Animal', color: 'bg-yellow-100 text-yellow-700' },
    vaccine: { label: 'Carteira de Vacinas', color: 'bg-green-100 text-green-700' },
    exam: { label: 'Resultado de Exame', color: 'bg-purple-100 text-purple-700' },
    prescription: { label: 'Receita', color: 'bg-blue-100 text-blue-700' },
    report: { label: 'Laudo', color: 'bg-orange-100 text-orange-700' },
    other: { label: 'Outro', color: 'bg-gray-100 text-gray-700' },
};

interface PetDocument {
    id: number;
    title: string;
    document_type: string;
    file_name: string;
    file_type: string;
    file_size: number;
    document_date: string | null;
    expiry_date: string | null;
    created_at: string;
}

function DocumentsTab({ petId }: { petId: number }) {
    const queryClient = useQueryClient();
    const { data: docs, isLoading } = useQuery<PetDocument[]>({
        queryKey: ['documents', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/documents`)).data,
    });

    const downloadMutation = useMutation({
        mutationFn: async (docId: number) => {
            const res = await api.get(`/pets/${petId}/documents/${docId}/download`);
            window.open(res.data.download_url, '_blank');
        },
        onSuccess: () => {
            toast.success('Download iniciado.');
        },
        onError: () => {
            toast.error('Erro ao baixar documento.');
        }
    });

    const deleteMutation = useMutation({
        mutationFn: async (docId: number) => api.delete(`/pets/${petId}/documents/${docId}`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['documents', petId] });
            toast.success('Arquivo removido com sucesso.');
        },
        onError: () => {
            toast.error('Erro ao remover arquivo.');
        }
    });

    const formatBytes = (bytes: number) => {
        if (bytes < 1024) return `${bytes} B`;
        if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
    };

    return (
        <Card>
            <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-base">Documentos</CardTitle>
                <UploadDocumentModal petId={petId} />
            </CardHeader>
            <CardContent>
                {isLoading ? (
                    <div className="flex justify-center py-8">
                        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                    </div>
                ) : !docs?.length ? (
                    <p className="text-center text-sm text-muted-foreground py-8">
                        Nenhum documento encontrado.
                    </p>
                ) : (
                    <div className="space-y-3">
                        {docs.map((doc) => {
                            const typeInfo = docTypeLabel[doc.document_type] ?? docTypeLabel.other;
                            const isExpired = doc.expiry_date && new Date(doc.expiry_date) < new Date();
                            return (
                                <div key={doc.id} className="flex items-start gap-3 rounded-lg border p-3">
                                    <div className="mt-0.5 rounded p-1.5 bg-gray-100">
                                        <FileText className="h-4 w-4 text-gray-500" />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2 flex-wrap">
                                            <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${typeInfo.color}`}>
                                                {typeInfo.label}
                                            </span>
                                            <span className="font-medium text-sm truncate">{doc.title}</span>
                                            {isExpired && (
                                                <span className="rounded-full px-2 py-0.5 text-xs font-medium bg-red-100 text-red-700">
                                                    Vencido
                                                </span>
                                            )}
                                        </div>
                                        <p className="text-xs text-muted-foreground mt-0.5 truncate">
                                            {doc.file_name} • {formatBytes(doc.file_size)}
                                            {doc.document_date && ` • ${new Date(doc.document_date).toLocaleDateString('pt-BR')}`}
                                            {doc.expiry_date && ` • Validade: ${new Date(doc.expiry_date).toLocaleDateString('pt-BR')}`}
                                        </p>
                                    </div>
                                    <div className="flex gap-1 shrink-0">
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-7 w-7"
                                            title="Baixar"
                                            onClick={() => downloadMutation.mutate(doc.id)}
                                            disabled={downloadMutation.isPending}
                                        >
                                            {downloadMutation.isPending ? (
                                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                            ) : (
                                                <FileText className="h-3.5 w-3.5" />
                                            )}
                                        </Button>
                                        <Button
                                            variant="ghost"
                                            size="icon"
                                            className="h-7 w-7 text-red-500 hover:text-red-700 hover:bg-red-50"
                                            title="Remover"
                                            onClick={() => deleteMutation.mutate(doc.id)}
                                            disabled={deleteMutation.isPending}
                                        >
                                            {deleteMutation.isPending ? (
                                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                            ) : (
                                                <Trash2 className="h-3.5 w-3.5" />
                                            )}
                                        </Button>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </CardContent>
        </Card>
    );
}

export default function PetDetailPage() {
    const params = useParams();
    const router = useRouter();
    const queryClient = useQueryClient();
    const petId = Number(params.id);
    const [recordFilter, setRecordFilter] = useState<string>('all');

    const { data: pet, isLoading: petLoading } = useQuery<Pet>({
        queryKey: ['pet', petId],
        queryFn: async () => (await api.get(`/pets/${petId}`)).data,
    });

    const { data: records, isLoading: recordsLoading } = useQuery<MedicalRecord[]>({
        queryKey: ['records', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/records`)).data,
    });

    const { data: medications, isLoading: medsLoading } = useQuery<Medication[]>({
        queryKey: ['medications', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/medications`)).data,
    });

    const { data: veterinarians, isLoading: vetsLoading } = useQuery<Veterinarian[]>({
        queryKey: ['veterinarians', petId],
        queryFn: async () => (await api.get(`/pets/${petId}/veterinarians`)).data,
    });

    const deleteMutation = useMutation({
        mutationFn: async () => api.delete(`/pets/${petId}`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['pets'] });
            toast.success('Pet removido com sucesso.');
            router.push('/pets');
        },
        onError: () => {
            toast.error('Erro ao remover pet.');
        },
    });

    if (petLoading) {
        return (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
            </div>
        );
    }

    if (!pet) {
        return (
            <div className="flex h-96 flex-col items-center justify-center gap-4 text-muted-foreground">
                <AlertTriangle className="h-12 w-12" />
                <p>Pet não encontrado.</p>
                <Button asChild variant="outline">
                    <Link href="/pets">Voltar para lista</Link>
                </Button>
            </div>
        );
    }

    const vaccines = records?.filter((r) => r.type === 'vaccine') ?? [];
    const otherRecords = records?.filter((r) => r.type !== 'vaccine') ?? [];
    const filteredRecords = recordFilter === 'all'
        ? otherRecords
        : otherRecords.filter((r) => r.type === recordFilter);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex items-center gap-4">
                    <Button variant="ghost" size="icon" asChild>
                        <Link href="/pets">
                            <ArrowLeft className="h-4 w-4" />
                        </Link>
                    </Button>
                    <PetPhotoUpload petId={petId} photoUrl={pet.photo_url} petName={pet.name} />
                    <div>
                        <h1 className="text-2xl font-bold tracking-tight">{pet.name}</h1>
                        <p className="text-muted-foreground text-sm">
                            {speciesLabel[pet.species] ?? pet.species}
                            {pet.breed ? ` • ${pet.breed}` : ''}
                        </p>
                    </div>
                </div>
                <div className="flex gap-2 flex-wrap">
                    <PetQRCodeModal petId={petId} petName={pet.name} />
                    <Button variant="outline" asChild>
                        <Link href={`/pets/${petId}/card`}>
                            <CreditCard className="mr-2 h-4 w-4" />
                            Cartão
                        </Link>
                    </Button>
                    <Button variant="outline" asChild>
                        <Link href={`/pets/${petId}/edit`}>
                            <Edit className="mr-2 h-4 w-4" />
                            Editar
                        </Link>
                    </Button>
                    <AlertDialog>
                        <AlertDialogTrigger asChild>
                            <Button variant="destructive" size="icon">
                                <Trash2 className="h-4 w-4" />
                            </Button>
                        </AlertDialogTrigger>
                        <AlertDialogContent>
                            <AlertDialogHeader>
                                <AlertDialogTitle>Deletar {pet.name}?</AlertDialogTitle>
                                <AlertDialogDescription>
                                    Esta ação não pode ser desfeita. Todos os registros médicos,
                                    vacinas e medicamentos serão apagados.
                                </AlertDialogDescription>
                            </AlertDialogHeader>
                            <AlertDialogFooter>
                                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                <AlertDialogAction
                                    onClick={() => deleteMutation.mutate()}
                                    className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
                                >
                                    {deleteMutation.isPending ? (
                                        <Loader2 className="h-4 w-4 animate-spin" />
                                    ) : (
                                        'Deletar'
                                    )}
                                </AlertDialogAction>
                            </AlertDialogFooter>
                        </AlertDialogContent>
                    </AlertDialog>
                </div>
            </div>

            {/* Info Grid */}
            <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                <div className="rounded-2xl border bg-card/50 p-4 shadow-sm backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900/30">
                            <UserIcon className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                        </div>
                        <div>
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Sexo</p>
                            <p className="text-sm font-bold">{sexLabel[pet.sex ?? 'unknown'] ?? pet.sex}</p>
                        </div>
                    </div>
                </div>

                <div className="rounded-2xl border bg-card/50 p-4 shadow-sm backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-purple-100 dark:bg-purple-900/30">
                            <Calendar className="h-4 w-4 text-purple-600 dark:text-purple-400" />
                        </div>
                        <div>
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Nascimento</p>
                            <p className="text-sm font-bold">
                                {pet.birth_date
                                    ? new Date(pet.birth_date).toLocaleDateString('pt-BR')
                                    : 'Não informado'}
                            </p>
                        </div>
                    </div>
                </div>

                <div className="rounded-2xl border bg-card/50 p-4 shadow-sm backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/30">
                            <span className="text-sm">🎨</span>
                        </div>
                        <div>
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Cor / Pelagem</p>
                            <p className="text-sm font-bold">{pet.color || 'Não informado'}</p>
                        </div>
                    </div>
                </div>

                <div className="rounded-2xl border bg-card/50 p-4 shadow-sm backdrop-blur-sm">
                    <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30">
                            <CreditCard className="h-4 w-4 text-green-600 dark:text-green-400" />
                        </div>
                        <div>
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground font-semibold">Microchip</p>
                            <p className="text-sm font-bold font-mono">{pet.microchip || '—'}</p>
                        </div>
                    </div>
                </div>
            </div>

            {/* Tabs Navigation */}
            <Tabs defaultValue="timeline" className="w-full">
                <div className="overflow-x-auto pb-2 scrollbar-hide">
                    <TabsList className="inline-flex h-12 items-center justify-start rounded-xl bg-muted/50 p-1.5 text-muted-foreground gap-1 border">
                        <TabsTrigger
                            value="timeline"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <History className="mr-2 h-4 w-4" />
                            Timeline
                        </TabsTrigger>
                        <TabsTrigger
                            value="records"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <Stethoscope className="mr-2 h-4 w-4" />
                            Prontuário
                            <Badge variant="secondary" className="ml-1.5 h-5 px-1.5 text-[10px]">{otherRecords.length}</Badge>
                        </TabsTrigger>
                        <TabsTrigger
                            value="vaccines"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <Syringe className="mr-2 h-4 w-4" />
                            Vacinas
                            <Badge variant="secondary" className="ml-1.5 h-5 px-1.5 text-[10px]">{vaccines.length}</Badge>
                        </TabsTrigger>
                        <TabsTrigger
                            value="medications"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <Pill className="mr-2 h-4 w-4" />
                            Meds
                            <Badge variant="secondary" className="ml-1.5 h-5 px-1.5 text-[10px]">{medications?.length ?? 0}</Badge>
                        </TabsTrigger>
                        <TabsTrigger
                            value="documents"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <FileText className="mr-2 h-4 w-4" />
                            Documentos
                        </TabsTrigger>
                        <TabsTrigger
                            value="veterinarians"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <UserIcon className="mr-2 h-4 w-4" />
                            Vets
                        </TabsTrigger>
                        <TabsTrigger
                            value="biometry"
                            className="inline-flex items-center justify-center whitespace-nowrap rounded-lg px-4 py-2 text-sm font-medium transition-all data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm"
                        >
                            <ScanFace className="mr-2 h-4 w-4" />
                            Bio
                        </TabsTrigger>
                    </TabsList>
                </div>

                {/* Timeline Tab */}
                <TabsContent value="timeline" className="mt-6 animate-in fade-in-50 duration-300">
                    <Card className="overflow-hidden border-2 border-primary/5">
                        <CardHeader className="bg-muted/30">
                            <CardTitle className="text-base flex items-center gap-2">
                                <History className="h-5 w-5 text-primary" />
                                Linha do Tempo de Saúde
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="pt-6">
                            <HealthTimeline records={records || []} />
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Records Tab */}
                <TabsContent value="records" className="mt-4">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between gap-2 flex-wrap">
                            <CardTitle className="text-base">Histórico Médico</CardTitle>
                            <div className="flex items-center gap-2">
                                <Select value={recordFilter} onValueChange={setRecordFilter}>
                                    <SelectTrigger className="h-8 w-[160px] text-xs">
                                        <SelectValue placeholder="Tipo" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="all">Todos os tipos</SelectItem>
                                        <SelectItem value="consultation">Consulta</SelectItem>
                                        <SelectItem value="exam">Exame</SelectItem>
                                        <SelectItem value="surgery">Cirurgia</SelectItem>
                                        <SelectItem value="other">Outro</SelectItem>
                                    </SelectContent>
                                </Select>
                                <AddRecordModal petId={petId} defaultType="consultation" />
                            </div>
                        </CardHeader>
                        <CardContent>
                            {recordsLoading ? (
                                <div className="flex justify-center py-8">
                                    <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                                </div>
                            ) : filteredRecords.length === 0 ? (
                                <p className="text-center text-sm text-muted-foreground py-8">
                                    {recordFilter !== 'all' ? 'Nenhum registro desse tipo.' : 'Nenhum registro encontrado.'}
                                </p>
                            ) : (
                                <div className="space-y-3">
                                    {filteredRecords.map((record: MedicalRecord) => {
                                        const typeInfo = recordTypeLabel[record.type] ?? recordTypeLabel.other;
                                        return (
                                            <div key={record.id} className="flex gap-3 rounded-lg border p-3">
                                                <div className="flex-1">
                                                    <div className="flex items-center gap-2 flex-wrap">
                                                        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${typeInfo.color}`}>
                                                            {typeInfo.label}
                                                        </span>
                                                        <span className="font-medium text-sm">{record.title}</span>
                                                    </div>
                                                    <div className="mt-1 flex flex-wrap gap-x-4 text-xs text-muted-foreground">
                                                        <span>{new Date(record.event_date).toLocaleDateString('pt-BR')}</span>
                                                        {record.veterinarian && <span>🩺 {record.veterinarian}</span>}
                                                        {record.clinic && <span>🏥 {record.clinic}</span>}
                                                    </div>
                                                    {record.notes && (
                                                        <p className="mt-1 text-xs text-muted-foreground line-clamp-2">
                                                            {record.notes}
                                                        </p>
                                                    )}
                                                    <div className="mt-2">
                                                        <RecordAttachmentsButton recordId={record.id} recordTitle={record.title} />
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Vaccines Tab */}
                <TabsContent value="vaccines" className="mt-4">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between">
                            <CardTitle className="text-base">Carteira de Vacinas</CardTitle>
                            <AddRecordModal petId={petId} defaultType="vaccine" />
                        </CardHeader>
                        <CardContent>
                            {recordsLoading ? (
                                <div className="flex justify-center py-8">
                                    <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                                </div>
                            ) : vaccines.length === 0 ? (
                                <p className="text-center text-sm text-muted-foreground py-8">
                                    Nenhuma vacina registrada.
                                </p>
                            ) : (
                                <div className="space-y-3">
                                    {vaccines.map((vaccine: MedicalRecord) => {
                                        const isOld = new Date(vaccine.event_date) < new Date();
                                        return (
                                            <div key={vaccine.id} className="flex items-start gap-3 rounded-lg border p-3">
                                                <div className={`mt-0.5 rounded-full p-1 ${isOld ? 'bg-green-100' : 'bg-yellow-100'}`}>
                                                    <Syringe className={`h-3.5 w-3.5 ${isOld ? 'text-green-600' : 'text-yellow-600'}`} />
                                                </div>
                                                <div className="flex-1">
                                                    <p className="font-medium text-sm">{vaccine.title}</p>
                                                    <p className="text-xs text-muted-foreground">
                                                        {new Date(vaccine.event_date).toLocaleDateString('pt-BR')}
                                                        {vaccine.veterinarian && ` • ${vaccine.veterinarian}`}
                                                    </p>
                                                </div>
                                                <Badge variant={isOld ? 'secondary' : 'outline'} className="text-xs">
                                                    {isOld ? 'Aplicada' : 'Agendada'}
                                                </Badge>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Medications Tab */}
                <TabsContent value="medications" className="mt-4">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between">
                            <CardTitle className="text-base">Medicamentos</CardTitle>
                            <AddMedicationModal petId={petId} />
                        </CardHeader>
                        <CardContent>
                            {medsLoading ? (
                                <div className="flex justify-center py-8">
                                    <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                                </div>
                            ) : !medications?.length ? (
                                <p className="text-center text-sm text-muted-foreground py-8">
                                    Nenhum medicamento registrado.
                                </p>
                            ) : (
                                <div className="space-y-3">
                                    {medications.map((med) => (
                                        <div key={med.id} className="flex items-start gap-3 rounded-lg border p-3">
                                            <div className={`mt-0.5 rounded-full p-1 ${med.is_active ? 'bg-blue-100' : 'bg-gray-100'}`}>
                                                <Pill className={`h-3.5 w-3.5 ${med.is_active ? 'text-blue-600' : 'text-gray-400'}`} />
                                            </div>
                                            <div className="flex-1">
                                                <p className="font-medium text-sm">{med.name}</p>
                                                <p className="text-xs text-muted-foreground">
                                                    {med.dosage} • {med.frequency}
                                                    {med.prescribed_by && ` • Dr(a). ${med.prescribed_by}`}
                                                </p>
                                                <p className="text-xs text-muted-foreground">
                                                    Início: {new Date(med.start_date).toLocaleDateString('pt-BR')}
                                                    {med.end_date && ` • Fim: ${new Date(med.end_date).toLocaleDateString('pt-BR')}`}
                                                </p>
                                            </div>
                                            <Badge variant={med.is_active ? 'default' : 'secondary'} className="text-xs">
                                                {med.is_active ? 'Ativo' : 'Inativo'}
                                            </Badge>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Veterinarians Tab */}
                <TabsContent value="veterinarians" className="mt-4">
                    <Card>
                        <CardHeader className="flex flex-row items-center justify-between">
                            <CardTitle className="text-base">Veterinários</CardTitle>
                            <AddVetModal petId={petId} />
                        </CardHeader>
                        <CardContent>
                            {vetsLoading ? (
                                <div className="flex justify-center py-8">
                                    <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                                </div>
                            ) : !veterinarians?.length ? (
                                <p className="text-center text-sm text-muted-foreground py-8">
                                    Nenhum veterinário cadastrado.
                                </p>
                            ) : (
                                <div className="space-y-3">
                                    {veterinarians.map((vet) => (
                                        <div key={vet.id} className="rounded-lg border p-4 space-y-2">
                                            <div className="flex items-start justify-between">
                                                <div>
                                                    <p className="font-semibold text-sm">{vet.name}</p>
                                                    {vet.specialty && (
                                                        <p className="text-xs text-muted-foreground">{vet.specialty}</p>
                                                    )}
                                                </div>
                                                {vet.clinic_name && (
                                                    <span className="text-xs bg-blue-50 text-blue-700 rounded-full px-2 py-0.5">
                                                        🏥 {vet.clinic_name}
                                                    </span>
                                                )}
                                            </div>
                                            <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                                                {vet.phone && (
                                                    <a href={`tel:${vet.phone}`} className="flex items-center gap-1 hover:text-primary">
                                                        <Phone className="h-3.5 w-3.5" />
                                                        {vet.phone}
                                                    </a>
                                                )}
                                                {vet.email && (
                                                    <a href={`mailto:${vet.email}`} className="flex items-center gap-1 hover:text-primary">
                                                        <Mail className="h-3.5 w-3.5" />
                                                        {vet.email}
                                                    </a>
                                                )}
                                                {vet.address && (
                                                    <span className="flex items-center gap-1">
                                                        <MapPinIcon className="h-3.5 w-3.5" />
                                                        {vet.address}
                                                    </span>
                                                )}
                                            </div>
                                            {vet.notes && (
                                                <p className="text-xs text-muted-foreground italic">{vet.notes}</p>
                                            )}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Documents Tab */}
                <TabsContent value="documents" className="mt-4">
                    <DocumentsTab petId={petId} />
                </TabsContent>

                {/* Biometry Tab */}
                <TabsContent value="biometry" className="mt-4">
                    <BiometryTab petId={petId} petName={pet.name} />
                </TabsContent>
            </Tabs>
        </div>
    );
}

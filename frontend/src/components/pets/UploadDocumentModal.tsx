'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Loader2, Plus, FileUp } from 'lucide-react';
import api from '@/lib/axios';

import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
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
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';

const schema = z.object({
    title: z.string().min(1, 'Título é obrigatório'),
    document_type: z.string().min(1, 'Tipo é obrigatório'),
    description: z.string().optional(),
    document_date: z.string().optional(),
    expiry_date: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

const docTypes = [
    { value: 'rg_animal', label: 'RG Animal' },
    { value: 'vaccine', label: 'Carteira de Vacinação' },
    { value: 'exam', label: 'Resultado de Exame' },
    { value: 'prescription', label: 'Receita Médica' },
    { value: 'report', label: 'Laudo Veterinário' },
    { value: 'other', label: 'Outro' },
];

interface UploadDocumentModalProps {
    petId: number;
}

export default function UploadDocumentModal({ petId }: UploadDocumentModalProps) {
    const [open, setOpen] = useState(false);
    const [file, setFile] = useState<File | null>(null);
    const [fileError, setFileError] = useState('');
    const queryClient = useQueryClient();

    const form = useForm<FormValues>({
        resolver: zodResolver(schema),
        defaultValues: {
            title: '',
            document_type: '',
            description: '',
            document_date: '',
            expiry_date: '',
        },
    });

    const mutation = useMutation({
        mutationFn: async (values: FormValues) => {
            if (!file) throw new Error('Arquivo obrigatório');
            const formData = new FormData();
            formData.append('file', file);
            formData.append('title', values.title);
            formData.append('document_type', values.document_type);
            if (values.description) formData.append('description', values.description);
            if (values.document_date) formData.append('document_date', values.document_date);
            if (values.expiry_date) formData.append('expiry_date', values.expiry_date);

            return api.post(`/pets/${petId}/documents`, formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
            });
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['documents', petId] });
            setOpen(false);
            setFile(null);
            form.reset();
        },
    });

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const f = e.target.files?.[0];
        if (!f) return;
        const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'];
        if (!allowed.includes(f.type)) {
            setFileError('Apenas PDF, JPG ou PNG.');
            setFile(null);
        } else {
            setFileError('');
            setFile(f);
        }
    };

    const onSubmit = (values: FormValues) => {
        if (!file) { setFileError('Selecione um arquivo.'); return; }
        mutation.mutate(values);
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button size="sm">
                    <Plus className="mr-2 h-4 w-4" />
                    Adicionar Documento
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[480px]">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <FileUp className="h-5 w-5 text-primary" />
                        Upload de Documento
                    </DialogTitle>
                    <DialogDescription>
                        Aceita PDF, JPG ou PNG. Tamanho máximo: 10MB.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                        {/* File input */}
                        <div className="space-y-1">
                            <label className="text-sm font-medium">Arquivo *</label>
                            <div className="flex items-center gap-2">
                                <label
                                    htmlFor="doc-file"
                                    className="flex flex-1 cursor-pointer items-center gap-2 rounded-md border border-dashed px-3 py-2 text-sm text-muted-foreground hover:bg-muted/50 transition-colors"
                                >
                                    <FileUp className="h-4 w-4 shrink-0" />
                                    {file ? file.name : 'Clique para selecionar...'}
                                </label>
                                <input
                                    id="doc-file"
                                    type="file"
                                    accept=".pdf,.jpg,.jpeg,.png"
                                    className="hidden"
                                    onChange={handleFileChange}
                                />
                            </div>
                            {fileError && <p className="text-xs text-red-500">{fileError}</p>}
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="title"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Título *</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Ex: Exame de Sangue - Jan/2025" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="document_type"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Tipo *</FormLabel>
                                        <Select onValueChange={field.onChange} defaultValue={field.value}>
                                            <FormControl>
                                                <SelectTrigger>
                                                    <SelectValue placeholder="Selecione o tipo" />
                                                </SelectTrigger>
                                            </FormControl>
                                            <SelectContent>
                                                {docTypes.map((t) => (
                                                    <SelectItem key={t.value} value={t.value}>
                                                        {t.label}
                                                    </SelectItem>
                                                ))}
                                            </SelectContent>
                                        </Select>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="document_date"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Data do Documento</FormLabel>
                                        <FormControl>
                                            <Input type="date" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="expiry_date"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Validade</FormLabel>
                                        <FormControl>
                                            <Input type="date" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </div>

                        {mutation.isError && (
                            <p className="text-sm text-red-500">Erro ao enviar. Tente novamente.</p>
                        )}
                        <DialogFooter>
                            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
                                Cancelar
                            </Button>
                            <Button type="submit" disabled={mutation.isPending}>
                                {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Enviar
                            </Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    );
}

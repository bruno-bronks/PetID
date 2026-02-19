'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Loader2, Plus } from 'lucide-react';
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
import { Textarea } from '@/components/ui/textarea';

const recordSchema = z.object({
    type: z.enum(['consultation', 'vaccine', 'exam', 'surgery', 'other']),
    title: z.string().min(1, 'Título é obrigatório'),
    event_date: z.string().min(1, 'Data é obrigatória'),
    veterinarian: z.string().optional(),
    clinic: z.string().optional(),
    notes: z.string().optional(),
});

type RecordFormValues = z.infer<typeof recordSchema>;

const typeOptions = [
    { value: 'consultation', label: '🩺 Consulta' },
    { value: 'vaccine', label: '💉 Vacina' },
    { value: 'exam', label: '🔬 Exame' },
    { value: 'surgery', label: '🏥 Cirurgia' },
    { value: 'other', label: '📋 Outro' },
];

interface AddRecordModalProps {
    petId: number;
    defaultType?: 'consultation' | 'vaccine' | 'exam' | 'surgery' | 'other';
}

export default function AddRecordModal({ petId, defaultType = 'consultation' }: AddRecordModalProps) {
    const [open, setOpen] = useState(false);
    const queryClient = useQueryClient();

    const form = useForm<RecordFormValues>({
        resolver: zodResolver(recordSchema),
        defaultValues: {
            type: defaultType,
            title: '',
            event_date: new Date().toISOString().split('T')[0],
            veterinarian: '',
            clinic: '',
            notes: '',
        },
    });

    const mutation = useMutation({
        mutationFn: async (values: RecordFormValues) => {
            const payload = {
                ...values,
                pet_id: petId,
            };
            return api.post(`/pets/${petId}/records`, payload);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['records', petId] });
            queryClient.invalidateQueries({ queryKey: ['vaccines'] });
            setOpen(false);
            form.reset();
        },
    });

    const onSubmit = (values: RecordFormValues) => {
        mutation.mutate(values);
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button size="sm">
                    <Plus className="mr-2 h-4 w-4" />
                    Adicionar Registro
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[520px]">
                <DialogHeader>
                    <DialogTitle>Novo Registro Médico</DialogTitle>
                    <DialogDescription>
                        Adicione uma consulta, vacina, exame ou procedimento ao prontuário.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="type"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Tipo *</FormLabel>
                                        <Select onValueChange={field.onChange} defaultValue={field.value}>
                                            <FormControl>
                                                <SelectTrigger>
                                                    <SelectValue />
                                                </SelectTrigger>
                                            </FormControl>
                                            <SelectContent>
                                                {typeOptions.map((opt) => (
                                                    <SelectItem key={opt.value} value={opt.value}>
                                                        {opt.label}
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
                                name="event_date"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Data *</FormLabel>
                                        <FormControl>
                                            <Input type="date" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </div>

                        <FormField
                            control={form.control}
                            name="title"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Título *</FormLabel>
                                    <FormControl>
                                        <Input placeholder="Ex: Vacina Antirrábica, Consulta de rotina..." {...field} />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="veterinarian"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Veterinário</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Nome do vet." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="clinic"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Clínica</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Nome da clínica" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </div>

                        <FormField
                            control={form.control}
                            name="notes"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Observações</FormLabel>
                                    <FormControl>
                                        <Textarea
                                            placeholder="Notas adicionais..."
                                            className="resize-none"
                                            rows={3}
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        {mutation.isError && (
                            <p className="text-sm text-red-500">
                                Erro ao salvar registro. Tente novamente.
                            </p>
                        )}

                        <DialogFooter>
                            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
                                Cancelar
                            </Button>
                            <Button type="submit" disabled={mutation.isPending}>
                                {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Salvar
                            </Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    );
}

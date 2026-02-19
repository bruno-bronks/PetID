'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Loader2, Plus, Pill } from 'lucide-react';
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
import { Textarea } from '@/components/ui/textarea';

const medSchema = z.object({
    name: z.string().min(1, 'Nome é obrigatório'),
    dosage: z.string().min(1, 'Dosagem é obrigatória'),
    frequency: z.string().min(1, 'Frequência é obrigatória'),
    instructions: z.string().optional(),
    start_date: z.string().min(1, 'Data de início é obrigatória'),
    end_date: z.string().optional(),
    prescribed_by: z.string().optional(),
    notes: z.string().optional(),
});

type MedFormValues = z.infer<typeof medSchema>;

interface AddMedicationModalProps {
    petId: number;
}

export default function AddMedicationModal({ petId }: AddMedicationModalProps) {
    const [open, setOpen] = useState(false);
    const queryClient = useQueryClient();

    const form = useForm<MedFormValues>({
        resolver: zodResolver(medSchema),
        defaultValues: {
            name: '',
            dosage: '',
            frequency: '',
            instructions: '',
            start_date: new Date().toISOString().split('T')[0],
            end_date: '',
            prescribed_by: '',
            notes: '',
        },
    });

    const mutation = useMutation({
        mutationFn: async (values: MedFormValues) => {
            const payload = {
                ...values,
                end_date: values.end_date || null,
                reminder_enabled: false,
                reminder_times: [],
            };
            return api.post(`/pets/${petId}/medications`, payload);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['medications', petId] });
            setOpen(false);
            form.reset();
        },
    });

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button size="sm">
                    <Plus className="mr-2 h-4 w-4" />
                    Adicionar Medicamento
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[520px]">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Pill className="h-5 w-5 text-primary" />
                        Novo Medicamento
                    </DialogTitle>
                    <DialogDescription>
                        Registre um medicamento em uso ou prescrito para o pet.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit((v) => mutation.mutate(v))} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="name"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Nome do Medicamento *</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Ex: Frontline, Drontal, Metronidazol..." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="dosage"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Dosagem *</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Ex: 1 comprimido, 5ml..." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="frequency"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Frequência *</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Ex: 2x ao dia, a cada 8h..." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="start_date"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Data Início *</FormLabel>
                                        <FormControl>
                                            <Input type="date" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="end_date"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Data Fim</FormLabel>
                                        <FormControl>
                                            <Input type="date" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="prescribed_by"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Prescrito por</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Nome do veterinário" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="instructions"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Instruções de uso</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Ex: Dar com alimento, evitar sol..." {...field} />
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
                                        <Textarea rows={2} className="resize-none" placeholder="Notas adicionais..." {...field} />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        {mutation.isError && (
                            <p className="text-sm text-red-500">Erro ao salvar. Tente novamente.</p>
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

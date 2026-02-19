'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Loader2, Plus, Stethoscope } from 'lucide-react';
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

const vetSchema = z.object({
    name: z.string().min(1, 'Nome é obrigatório'),
    clinic_name: z.string().optional(),
    phone: z.string().optional(),
    email: z.string().email('E-mail inválido').optional().or(z.literal('')),
    address: z.string().optional(),
    specialty: z.string().optional(),
    notes: z.string().optional(),
});

type VetFormValues = z.infer<typeof vetSchema>;

interface AddVetModalProps {
    petId: number;
}

export default function AddVetModal({ petId }: AddVetModalProps) {
    const [open, setOpen] = useState(false);
    const queryClient = useQueryClient();

    const form = useForm<VetFormValues>({
        resolver: zodResolver(vetSchema),
        defaultValues: {
            name: '',
            clinic_name: '',
            phone: '',
            email: '',
            address: '',
            specialty: '',
            notes: '',
        },
    });

    const mutation = useMutation({
        mutationFn: async (values: VetFormValues) =>
            api.post(`/pets/${petId}/veterinarians`, values),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['veterinarians', petId] });
            setOpen(false);
            form.reset();
        },
    });

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button size="sm">
                    <Plus className="mr-2 h-4 w-4" />
                    Adicionar Veterinário
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[520px]">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2">
                        <Stethoscope className="h-5 w-5 text-primary" />
                        Novo Veterinário
                    </DialogTitle>
                    <DialogDescription>
                        Adicione as informações de contato do veterinário.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit((v) => mutation.mutate(v))} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="name"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Nome *</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Dr. João Silva" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="specialty"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Especialidade</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Clínico geral, Oncologia..." {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="clinic_name"
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
                            <FormField
                                control={form.control}
                                name="phone"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Telefone</FormLabel>
                                        <FormControl>
                                            <Input placeholder="(11) 99999-9999" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="email"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>E-mail</FormLabel>
                                        <FormControl>
                                            <Input placeholder="vet@clinica.com" type="email" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="address"
                                render={({ field }) => (
                                    <FormItem className="col-span-2">
                                        <FormLabel>Endereço</FormLabel>
                                        <FormControl>
                                            <Input placeholder="Rua, número, bairro, cidade" {...field} />
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
                                            rows={2}
                                            placeholder="Notas adicionais..."
                                            className="resize-none"
                                            {...field}
                                        />
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

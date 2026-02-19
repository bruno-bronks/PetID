'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useMutation, useQueryClient, useQuery } from '@tanstack/react-query';
import { Loader2, Plus, AlertTriangle } from 'lucide-react';
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

const schema = z.object({
    pet_id: z.string().min(1, 'Selecione um pet'),
    description: z.string().min(1, 'Descrição é obrigatória'),
    event_date: z.string().min(1, 'Data é obrigatória'),
    city: z.string().optional(),
    address: z.string().optional(),
    contact_phone: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

interface Pet {
    id: number;
    name: string;
    species: string;
}

export default function ReportLostPetModal() {
    const [open, setOpen] = useState(false);
    const queryClient = useQueryClient();

    const { data: pets } = useQuery<Pet[]>({
        queryKey: ['pets'],
        queryFn: async () => (await api.get('/pets/')).data,
        enabled: open,
    });

    const form = useForm<FormValues>({
        resolver: zodResolver(schema),
        defaultValues: {
            pet_id: '',
            description: '',
            event_date: new Date().toISOString().split('T')[0],
            city: '',
            address: '',
            contact_phone: '',
        },
    });

    const mutation = useMutation({
        mutationFn: async (values: FormValues) => {
            const payload = {
                pet_id: parseInt(values.pet_id),
                description: values.description,
                event_date: values.event_date,
                city: values.city || null,
                address: values.address || null,
                contact_phone: values.contact_phone || null,
                contact_visible: true,
                latitude: 0,
                longitude: 0,
            };
            return api.post('/public/lost-pets/report', payload);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['lost-pets'] });
            setOpen(false);
            form.reset();
        },
    });

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button variant="destructive">
                    <AlertTriangle className="mr-2 h-4 w-4" />
                    Reportar Pet Perdido
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px]">
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2 text-red-600">
                        <AlertTriangle className="h-5 w-5" />
                        Reportar Pet Perdido
                    </DialogTitle>
                    <DialogDescription>
                        Preencha os dados para alertar a comunidade. Seu contato será exibido para ajudar na busca.
                    </DialogDescription>
                </DialogHeader>
                <Form {...form}>
                    <form onSubmit={form.handleSubmit((v) => mutation.mutate(v))} className="space-y-4">
                        <FormField
                            control={form.control}
                            name="pet_id"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Pet *</FormLabel>
                                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                                        <FormControl>
                                            <SelectTrigger>
                                                <SelectValue placeholder="Selecione o pet perdido" />
                                            </SelectTrigger>
                                        </FormControl>
                                        <SelectContent>
                                            {pets?.map((pet) => (
                                                <SelectItem key={pet.id} value={String(pet.id)}>
                                                    {pet.name} ({pet.species})
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
                                    <FormLabel>Data do Desaparecimento *</FormLabel>
                                    <FormControl>
                                        <Input type="date" {...field} />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <div className="grid grid-cols-2 gap-4">
                            <FormField
                                control={form.control}
                                name="city"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Cidade</FormLabel>
                                        <FormControl>
                                            <Input placeholder="São Paulo" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                            <FormField
                                control={form.control}
                                name="contact_phone"
                                render={({ field }) => (
                                    <FormItem>
                                        <FormLabel>Telefone de Contato</FormLabel>
                                        <FormControl>
                                            <Input placeholder="(11) 99999-9999" {...field} />
                                        </FormControl>
                                        <FormMessage />
                                    </FormItem>
                                )}
                            />
                        </div>

                        <FormField
                            control={form.control}
                            name="address"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Local onde foi visto pela última vez</FormLabel>
                                    <FormControl>
                                        <Input placeholder="Rua, bairro..." {...field} />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        <FormField
                            control={form.control}
                            name="description"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Descrição *</FormLabel>
                                    <FormControl>
                                        <Textarea
                                            rows={3}
                                            className="resize-none"
                                            placeholder="Descreva o pet, onde desapareceu e qualquer detalhe relevante..."
                                            {...field}
                                        />
                                    </FormControl>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />

                        {mutation.isError && (
                            <p className="text-sm text-red-500">Erro ao reportar. Tente novamente.</p>
                        )}

                        <DialogFooter>
                            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
                                Cancelar
                            </Button>
                            <Button type="submit" variant="destructive" disabled={mutation.isPending}>
                                {mutation.isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Reportar
                            </Button>
                        </DialogFooter>
                    </form>
                </Form>
            </DialogContent>
        </Dialog>
    );
}

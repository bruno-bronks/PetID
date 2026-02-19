'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
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

const petSchema = z.object({
    name: z.string().min(1, 'Nome é obrigatório'),
    species: z.enum(['dog', 'cat', 'other']),
    breed: z.string().optional(),
    sex: z.enum(['male', 'female', 'unknown']).optional(),
    birth_date: z.string().optional(),
    color: z.string().optional(),
    microchip: z.string().optional(),
    notes: z.string().optional(),
});

export type PetFormValues = z.infer<typeof petSchema>;

interface PetFormProps {
    defaultValues?: Partial<PetFormValues>;
    onSubmit: (values: PetFormValues) => Promise<void>;
    isLoading?: boolean;
    submitLabel?: string;
}

const speciesOptions = [
    { value: 'dog', label: '🐶 Cão' },
    { value: 'cat', label: '🐱 Gato' },
    { value: 'other', label: '🐾 Outro' },
];

const sexOptions = [
    { value: 'male', label: 'Macho' },
    { value: 'female', label: 'Fêmea' },
    { value: 'unknown', label: 'Não informado' },
];

export default function PetForm({ defaultValues, onSubmit, isLoading, submitLabel = 'Salvar' }: PetFormProps) {
    const form = useForm<PetFormValues>({
        resolver: zodResolver(petSchema),
        defaultValues: {
            name: '',
            species: undefined,
            breed: '',
            sex: 'unknown',
            birth_date: '',
            color: '',
            microchip: '',
            notes: '',
            ...defaultValues,
        },
    });

    return (
        <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <div className="grid gap-4 md:grid-cols-2">
                    {/* Name */}
                    <FormField
                        control={form.control}
                        name="name"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Nome *</FormLabel>
                                <FormControl>
                                    <Input placeholder="Nome do pet" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />

                    {/* Species */}
                    <FormField
                        control={form.control}
                        name="species"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Espécie *</FormLabel>
                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                    <FormControl>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Selecione a espécie" />
                                        </SelectTrigger>
                                    </FormControl>
                                    <SelectContent>
                                        {speciesOptions.map((opt) => (
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

                    {/* Breed */}
                    <FormField
                        control={form.control}
                        name="breed"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Raça</FormLabel>
                                <FormControl>
                                    <Input placeholder="Ex: Labrador" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />

                    {/* Sex */}
                    <FormField
                        control={form.control}
                        name="sex"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Sexo</FormLabel>
                                <Select onValueChange={field.onChange} defaultValue={field.value}>
                                    <FormControl>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Selecione o sexo" />
                                        </SelectTrigger>
                                    </FormControl>
                                    <SelectContent>
                                        {sexOptions.map((opt) => (
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

                    {/* Birth Date */}
                    <FormField
                        control={form.control}
                        name="birth_date"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Data de Nascimento</FormLabel>
                                <FormControl>
                                    <Input type="date" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />

                    {/* Color */}
                    <FormField
                        control={form.control}
                        name="color"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Cor / Pelagem</FormLabel>
                                <FormControl>
                                    <Input placeholder="Ex: Caramelo" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />

                    {/* Microchip */}
                    <FormField
                        control={form.control}
                        name="microchip"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Nº Microchip</FormLabel>
                                <FormControl>
                                    <Input placeholder="Número do microchip" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                </div>

                {/* Notes */}
                <FormField
                    control={form.control}
                    name="notes"
                    render={({ field }) => (
                        <FormItem>
                            <FormLabel>Observações</FormLabel>
                            <FormControl>
                                <Textarea
                                    placeholder="Informações adicionais sobre o pet..."
                                    className="resize-none"
                                    rows={3}
                                    {...field}
                                />
                            </FormControl>
                            <FormMessage />
                        </FormItem>
                    )}
                />

                <Button type="submit" disabled={isLoading} className="w-full md:w-auto">
                    {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                    {submitLabel}
                </Button>
            </form>
        </Form>
    );
}

'use client';

import { useRef, useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Camera, Loader2, Trash2, User as UserIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';
import Image from 'next/image';

interface PetPhotoUploadProps {
    petId: number;
    photoUrl?: string | null;
    petName: string;
}

export default function PetPhotoUpload({ petId, photoUrl, petName }: PetPhotoUploadProps) {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [preview, setPreview] = useState<string | null>(photoUrl ?? null);
    const queryClient = useQueryClient();

    const uploadMutation = useMutation({
        mutationFn: async (file: File) => {
            const formData = new FormData();
            formData.append('file', file);
            const res = await api.post(`/pets/${petId}/photo`, formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
            });
            return res.data as { photo_url: string };
        },
        onSuccess: (data) => {
            setPreview(data.photo_url);
            queryClient.invalidateQueries({ queryKey: ['pet', petId] });
        },
    });

    const removeMutation = useMutation({
        mutationFn: async () => api.patch(`/pets/${petId}`, { photo_url: null }),
        onSuccess: () => {
            setPreview(null);
            queryClient.invalidateQueries({ queryKey: ['pet', petId] });
        },
    });

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        // Preview local imediato
        const localUrl = URL.createObjectURL(file);
        setPreview(localUrl);
        uploadMutation.mutate(file);
    };

    const isLoading = uploadMutation.isPending || removeMutation.isPending;

    return (
        <div className="relative group w-28 h-28 shrink-0">
            {/* Avatar */}
            <div className="w-28 h-28 rounded-full overflow-hidden bg-primary/10 border-4 border-background shadow-md flex items-center justify-center">
                {preview ? (
                    <Image
                        src={preview}
                        alt={petName}
                        width={112}
                        height={112}
                        className="object-cover w-full h-full"
                        unoptimized
                    />
                ) : (
                    <UserIcon className="h-12 w-12 text-primary/40" />
                )}
            </div>

            {/* Overlay actions on hover */}
            {!isLoading && (
                <div className="absolute inset-0 rounded-full flex items-center justify-center gap-1 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity">
                    <Button
                        type="button"
                        variant="secondary"
                        size="icon"
                        className="h-7 w-7"
                        title="Alterar foto"
                        onClick={() => fileInputRef.current?.click()}
                    >
                        <Camera className="h-3.5 w-3.5" />
                    </Button>
                    {preview && (
                        <Button
                            type="button"
                            variant="destructive"
                            size="icon"
                            className="h-7 w-7"
                            title="Remover foto"
                            onClick={() => removeMutation.mutate()}
                        >
                            <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                    )}
                </div>
            )}

            {/* Spinner overlay during upload */}
            {isLoading && (
                <div className="absolute inset-0 rounded-full flex items-center justify-center bg-black/40">
                    <Loader2 className="h-6 w-6 text-white animate-spin" />
                </div>
            )}

            <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={handleFileChange}
            />
        </div>
    );
}

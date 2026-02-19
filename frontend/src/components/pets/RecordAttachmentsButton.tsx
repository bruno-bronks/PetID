'use client';

import { useRef, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/axios';
import { Paperclip, Upload, Loader2, FileImage, FileText, File as FileIcon, Download, Trash2, Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
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

interface Attachment {
    id: number;
    record_id: number;
    file_name: string;
    mime_type: string | null;
    file_size: number | null;
    uploaded_at: string;
}

interface AttachmentWithUrl extends Attachment {
    download_url?: string;
}

interface RecordAttachmentsButtonProps {
    recordId: number;
    recordTitle: string;
}

function formatFileSize(bytes: number | null): string {
    if (!bytes) return '';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1048576).toFixed(1)} MB`;
}

function getMimeIcon(mime: string | null) {
    if (!mime) return FileIcon;
    if (mime.startsWith('image/')) return FileImage;
    if (mime === 'application/pdf') return FileText;
    return FileIcon;
}

export default function RecordAttachmentsButton({ recordId, recordTitle }: RecordAttachmentsButtonProps) {
    const [open, setOpen] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const queryClient = useQueryClient();

    const { data: attachments = [], isLoading } = useQuery<AttachmentWithUrl[]>({
        queryKey: ['attachments', recordId],
        queryFn: async () => (await api.get(`/records/${recordId}/attachments`)).data,
        enabled: open,
    });

    const uploadMutation = useMutation({
        mutationFn: async (file: File) => {
            const formData = new FormData();
            formData.append('file', file);
            return (await api.post(`/records/${recordId}/attachments`, formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
            })).data;
        },
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['attachments', recordId] }),
    });

    const deleteMutation = useMutation({
        mutationFn: async (attachmentId: number) =>
            api.delete(`/records/${recordId}/attachments/${attachmentId}`),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['attachments', recordId] }),
    });

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) uploadMutation.mutate(file);
        e.target.value = '';
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button variant="ghost" size="sm" className="h-7 px-2 text-xs text-muted-foreground hover:text-foreground">
                    <Paperclip className="h-3.5 w-3.5 mr-1" />
                    Anexos
                </Button>
            </DialogTrigger>
            <DialogContent className="max-w-lg">
                <DialogHeader>
                    <DialogTitle className="text-base">Anexos — {recordTitle}</DialogTitle>
                </DialogHeader>

                {isLoading ? (
                    <div className="flex justify-center py-8">
                        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                    </div>
                ) : (
                    <div className="space-y-3">
                        {attachments.length === 0 ? (
                            <p className="text-center text-sm text-muted-foreground py-6">
                                Nenhum anexo neste registro.
                            </p>
                        ) : (
                            <div className="divide-y rounded-lg border">
                                {attachments.map((att) => {
                                    const Icon = getMimeIcon(att.mime_type);
                                    return (
                                        <div key={att.id} className="flex items-center gap-3 p-3">
                                            <Icon className="h-5 w-5 text-muted-foreground shrink-0" />
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-medium truncate">{att.file_name}</p>
                                                <p className="text-xs text-muted-foreground">
                                                    {formatFileSize(att.file_size)}
                                                    {att.file_size ? ' · ' : ''}
                                                    {new Date(att.uploaded_at).toLocaleDateString('pt-BR')}
                                                </p>
                                            </div>
                                            <div className="flex items-center gap-1 shrink-0">
                                                {att.download_url && (
                                                    <Button variant="ghost" size="icon" className="h-7 w-7" asChild>
                                                        <a href={att.download_url} target="_blank" rel="noopener noreferrer" download>
                                                            <Download className="h-3.5 w-3.5" />
                                                        </a>
                                                    </Button>
                                                )}
                                                <AlertDialog>
                                                    <AlertDialogTrigger asChild>
                                                        <Button variant="ghost" size="icon" className="h-7 w-7 text-red-400 hover:text-red-600">
                                                            <Trash2 className="h-3.5 w-3.5" />
                                                        </Button>
                                                    </AlertDialogTrigger>
                                                    <AlertDialogContent>
                                                        <AlertDialogHeader>
                                                            <AlertDialogTitle>Remover anexo?</AlertDialogTitle>
                                                            <AlertDialogDescription>
                                                                O arquivo &quot;{att.file_name}&quot; será removido permanentemente.
                                                            </AlertDialogDescription>
                                                        </AlertDialogHeader>
                                                        <AlertDialogFooter>
                                                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                            <AlertDialogAction
                                                                onClick={() => deleteMutation.mutate(att.id)}
                                                                className="bg-red-600 hover:bg-red-700"
                                                            >
                                                                Remover
                                                            </AlertDialogAction>
                                                        </AlertDialogFooter>
                                                    </AlertDialogContent>
                                                </AlertDialog>
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        )}

                        <div className="flex justify-end">
                            <Button
                                size="sm"
                                variant="outline"
                                onClick={() => fileInputRef.current?.click()}
                                disabled={uploadMutation.isPending}
                            >
                                {uploadMutation.isPending ? (
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                ) : (
                                    <Plus className="mr-2 h-4 w-4" />
                                )}
                                {uploadMutation.isPending ? 'Enviando...' : 'Adicionar anexo'}
                            </Button>
                            <input
                                ref={fileInputRef}
                                type="file"
                                accept="image/*,.pdf,.doc,.docx"
                                className="hidden"
                                onChange={handleFileChange}
                            />
                        </div>
                    </div>
                )}
            </DialogContent>
        </Dialog>
    );
}

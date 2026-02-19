'use client';

import { useRef } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { QrCode, Download, ExternalLink } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';

interface PetQRCodeModalProps {
    petId: number;
    petName: string;
}

export default function PetQRCodeModal({ petId, petName }: PetQRCodeModalProps) {
    const svgRef = useRef<HTMLDivElement>(null);

    const publicUrl =
        typeof window !== 'undefined'
            ? `${window.location.origin}/p/${petId}`
            : `/p/${petId}`;

    const handleDownload = () => {
        const svg = svgRef.current?.querySelector('svg');
        if (!svg) return;

        const svgData = new XMLSerializer().serializeToString(svg);
        const canvas = document.createElement('canvas');
        const SIZE = 600;
        canvas.width = SIZE;
        canvas.height = SIZE;
        const ctx = canvas.getContext('2d')!;
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, SIZE, SIZE);

        const img = new Image();
        const blob = new Blob([svgData], { type: 'image/svg+xml;charset=utf-8' });
        const url = URL.createObjectURL(blob);

        img.onload = () => {
            ctx.drawImage(img, 0, 0, SIZE, SIZE);
            URL.revokeObjectURL(url);
            const link = document.createElement('a');
            link.download = `qrcode-${petName.toLowerCase().replace(/\s+/g, '-')}.png`;
            link.href = canvas.toDataURL('image/png');
            link.click();
        };
        img.src = url;
    };

    return (
        <Dialog>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm">
                    <QrCode className="mr-2 h-4 w-4" />
                    QR Code
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-sm">
                <DialogHeader>
                    <DialogTitle>QR Code de {petName}</DialogTitle>
                    <DialogDescription>
                        Imprima e cole na coleira. Qualquer pessoa que escanear verá o perfil público do pet.
                    </DialogDescription>
                </DialogHeader>

                <div className="flex flex-col items-center gap-4 pt-2">
                    <div ref={svgRef} className="rounded-2xl border-4 border-primary/20 p-4 bg-white shadow-sm">
                        <QRCodeSVG
                            value={publicUrl}
                            size={220}
                            bgColor="#ffffff"
                            fgColor="#1e293b"
                            level="H"
                            includeMargin={false}
                        />
                    </div>

                    <p className="text-xs text-muted-foreground text-center break-all px-2">{publicUrl}</p>

                    <div className="flex gap-2 w-full">
                        <Button variant="outline" size="sm" className="flex-1" asChild>
                            <a href={publicUrl} target="_blank" rel="noopener noreferrer">
                                <ExternalLink className="mr-2 h-4 w-4" />
                                Visualizar
                            </a>
                        </Button>
                        <Button size="sm" className="flex-1" onClick={handleDownload}>
                            <Download className="mr-2 h-4 w-4" />
                            Baixar PNG
                        </Button>
                    </div>
                </div>
            </DialogContent>
        </Dialog>
    );
}

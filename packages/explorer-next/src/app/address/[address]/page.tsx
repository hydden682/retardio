import { Navbar } from "@/components/layout/navbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";
import { Coins, Copy, QrCode, Wallet } from "lucide-react";

export default function AddressPage({ params }: { params: { address: string } }) {
    const address = params.address;

    return (
        <div className="flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1 p-8 pt-6 container max-w-5xl mx-auto">
                <div className="mb-6 flex items-center justify-between">
                    <h1 className="text-2xl font-bold font-mono tracking-tight flex items-center gap-2">
                        <Wallet className="h-6 w-6 text-primary" />
                        <span className="truncate max-w-xl">{address}</span>
                    </h1>
                    <button className="p-2 border border-border rounded-lg bg-card-hover hover:text-primary transition-colors">
                        <Copy className="h-4 w-4" />
                    </button>
                </div>

                <div className="grid gap-6 md:grid-cols-2">
                    <Card>
                        <CardHeader><CardTitle>Balance</CardTitle></CardHeader>
                        <CardContent className="text-center py-6">
                            <div className="text-4xl font-bold font-mono text-secondary">
                                1,337.00 RTC
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardHeader><CardTitle>Total Received / Sent</CardTitle></CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-muted-foreground flex items-center gap-1"><Coins className="h-3 w-3" /> Received</span>
                                <span className="font-mono">50,000.00 RTC</span>
                            </div>
                            <div className="w-full h-1 bg-border rounded-full overflow-hidden">
                                <div className="h-full bg-green-500 w-[70%]" />
                            </div>
                            <div className="flex justify-between items-center text-sm">
                                <span className="text-muted-foreground flex items-center gap-1"><Coins className="h-3 w-3" /> Sent</span>
                                <span className="font-mono">48,663.00 RTC</span>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="md:col-span-2">
                        <CardHeader><CardTitle>History</CardTitle></CardHeader>
                        <CardContent>
                            <div className="text-center py-8 text-muted-foreground">
                                Transaction history loading...
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

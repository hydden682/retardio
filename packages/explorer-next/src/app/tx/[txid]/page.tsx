import { Navbar } from "@/components/layout/navbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";
import { ArrowLeft, ArrowRight, ArrowRightCircle } from "lucide-react";

export default function TxPage({ params }: { params: { txid: string } }) {
    const txid = params.txid;
    // TODO: Fetch real tx

    return (
        <div className="flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1 p-8 pt-6 container max-w-5xl mx-auto">
                <div className="mb-6 flex items-center gap-4">
                    <Link href="/" className="p-2 rounded-full hover:bg-white/10 transition-colors">
                        <ArrowLeft className="h-5 w-5" />
                    </Link>
                    <h1 className="text-2xl font-bold font-mono tracking-tight truncate max-w-2xl">
                        {txid}
                    </h1>
                </div>

                <div className="grid gap-6">
                    <Card>
                        <CardHeader>
                            <CardTitle>Transaction inputs & outputs</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex flex-col md:flex-row gap-8">
                                {/* Inputs */}
                                <div className="flex-1 space-y-3">
                                    <h3 className="text-sm font-semibold text-muted-foreground uppercase">Inputs (1)</h3>
                                    <div className="p-4 rounded-lg bg-card-hover border border-border/50 space-y-2">
                                        <div className="flex justify-between items-center text-sm">
                                            <Link href="#" className="text-primary hover:underline font-mono">rt1q...xy2z</Link>
                                            <span className="text-red-400 font-mono">- 500.00 RTC</span>
                                        </div>
                                    </div>
                                </div>

                                {/* Arrow */}
                                <div className="flex items-center justify-center">
                                    <ArrowRightCircle className="h-8 w-8 text-muted-foreground/30 rotate-90 md:rotate-0" />
                                </div>

                                {/* Outputs */}
                                <div className="flex-1 space-y-3">
                                    <h3 className="text-sm font-semibold text-muted-foreground uppercase">Outputs (2)</h3>
                                    <div className="p-4 rounded-lg bg-card-hover border border-border/50 space-y-2">
                                        <div className="flex justify-between items-center text-sm">
                                            <Link href="#" className="text-primary hover:underline font-mono">rt1q...abc1</Link>
                                            <span className="text-green-400 font-mono">+ 100.00 RTC</span>
                                        </div>
                                        <div className="border-t border-border/30 my-2"></div>
                                        <div className="flex justify-between items-center text-sm">
                                            <Link href="#" className="text-primary hover:underline font-mono">rt1q...def2</Link>
                                            <span className="text-green-400 font-mono">+ 399.99 RTC</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="mt-8 pt-6 border-t border-border flex justify-between items-center">
                                <span className="text-sm text-muted-foreground">Fee: <span className="text-foreground">0.01 RTC</span></span>
                                <span className="text-sm px-2 py-1 rounded bg-secondary/10 text-secondary border border-secondary/20">Confirmed</span>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

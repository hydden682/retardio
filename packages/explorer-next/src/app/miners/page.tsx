import { Navbar } from "@/components/layout/navbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";
import { Activity, Award, Pickaxe } from "lucide-react";

export default function MinersPage() {
    return (
        <div className="flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1 p-8 pt-6 container max-w-5xl mx-auto">
                <h1 className="text-3xl font-bold tracking-tight mb-6">Miners Distribution</h1>

                <div className="grid gap-6">
                    {/* Chart Placeholder */}
                    <Card>
                        <CardHeader><CardTitle>Hashrate Distribution (24h)</CardTitle></CardHeader>
                        <CardContent className="h-[300px] flex items-center justify-center bg-card-hover/20">
                            Pie Chart Placeholder
                        </CardContent>
                    </Card>

                    {/* Leaderboard */}
                    <Card>
                        <CardHeader><CardTitle>Top Miners (7 Days)</CardTitle></CardHeader>
                        <CardContent>
                            <div className="space-y-4">
                                {[1, 2, 3, 4, 5].map((i) => (
                                    <div key={i} className="flex items-center justify-between border-b border-border py-4 last:border-0">
                                        <div className="flex items-center gap-4">
                                            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-secondary/10 text-secondary font-bold">
                                                {i}
                                            </div>
                                            <div className="space-y-1">
                                                <div className="font-medium text-lg flex items-center gap-2">
                                                    {i === 1 ? 'RetardioPool' : 'RetardioSoloMiner'}
                                                    {i === 1 && <Award className="h-4 w-4 text-yellow-500" />}
                                                </div>
                                                <div className="text-xs text-muted-foreground font-mono">rt1q...address{i}</div>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <div className="font-bold">{1000 - (i * 150)} Blocks</div>
                                            <div className="text-xs text-muted-foreground">{(50 - i * 5).toFixed(1)}% Network Share</div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

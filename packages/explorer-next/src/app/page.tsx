import { Navbar } from "@/components/layout/navbar";
import { StatCard } from "@/components/dashboard/stat-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { api } from "@/lib/api";
import { Activity, Box, Coins, Server, Zap } from "lucide-react";
import Link from "next/link";

export default async function Home() {
    const stats = await api.getStats();
    const latestBlocks = await api.getLatestBlocks();

    return (
        <div className="flex min-h-screen flex-col">
            <Navbar />

            <main className="flex-1 space-y-8 p-8 pt-6">
                <div className="flex items-center justify-between space-y-2">
                    <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
                </div>

                {/* Network Stats Grid */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    <StatCard
                        title="Block Height"
                        value={stats.height.toLocaleString()}
                        icon={Box}
                        trend="up"
                        subValue="Latest block"
                    />
                    <StatCard
                        title="Sort Difficulty"
                        value={stats.difficulty}
                        icon={Zap}
                        subValue="Network Algo"
                    />
                    <StatCard
                        title="Network Hashrate"
                        value={stats.hashrate}
                        icon={Activity}
                        subValue="Estimated"
                    />
                    <StatCard
                        title="Circulating Supply"
                        value={stats.supply}
                        icon={Coins}
                        subValue="Max: 21M"
                    />
                </div>

                {/* Recent Blocks & Halving Info */}
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
                    <Card className="col-span-4">
                        <CardHeader>
                            <CardTitle>Recent Blocks</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-4">
                                {latestBlocks.map((block) => (
                                    <div key={block.height} className="flex items-center justify-between border-b border-border pb-4 last:border-0 last:pb-0">
                                        <div className="space-y-1">
                                            <Link href={`/block/${block.height}`} className="font-mono text-primary hover:underline">
                                                #{block.height}
                                            </Link>
                                            <p className="text-sm text-muted-foreground">
                                                {new Date(block.timestamp).toLocaleString()}
                                            </p>
                                        </div>
                                        <div className="text-right">
                                            <Link href={`/miners/${block.miner}`} className="text-sm font-medium hover:text-primary transition-colors">
                                                {block.miner}
                                            </Link>
                                            <p className="text-xs text-muted-foreground">
                                                {block.tx_count} txs • {block.size.toLocaleString()} bytes
                                            </p>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="col-span-3">
                        <CardHeader>
                            <CardTitle>Halving Countdown</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex flex-col items-center justify-center space-y-6 pt-4">
                                <div className="text-center">
                                    <div className="text-5xl font-bold text-primary font-mono tracking-tighter">
                                        42,000
                                    </div>
                                    <p className="text-sm text-muted-foreground mt-2">Blocks Remaining</p>
                                </div>

                                <div className="w-full space-y-2">
                                    <div className="flex justify-between text-xs text-muted-foreground">
                                        <span>Progress</span>
                                        <span>80%</span>
                                    </div>
                                    <div className="h-2 w-full bg-secondary/10 rounded-full overflow-hidden">
                                        <div className="h-full bg-secondary w-[80%] shadow-[0_0_10px_rgba(0,255,136,0.5)]" />
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4 w-full pt-4">
                                    <div className="flex flex-col items-center p-3 bg-card-hover rounded-lg">
                                        <span className="text-xs text-muted-foreground">Current Reward</span>
                                        <span className="text-lg font-bold">50 RTC</span>
                                    </div>
                                    <div className="flex flex-col items-center p-3 bg-card-hover rounded-lg">
                                        <span className="text-xs text-muted-foreground">Next Reward</span>
                                        <span className="text-lg font-bold">25 RTC</span>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

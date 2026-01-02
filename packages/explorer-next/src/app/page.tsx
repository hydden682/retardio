import { Navbar } from "@/components/layout/navbar";
import { StatCard } from "@/components/dashboard/stat-card";
import { BlockTape } from "@/components/dashboard/block-tape";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { api } from "@/lib/api";
import { Activity, Box, Coins, Server, Zap, Search } from "lucide-react";
import Link from "next/link";

export default async function Home() {
    const stats = await api.getStats();
    const latestBlocks = await api.getLatestBlocks();

    return (
        <div className="flex min-h-screen flex-col bg-background">
            <Navbar />

            {/* Horizontal Block Tape (Dripscan Style) */}
            <BlockTape blocks={latestBlocks} />

            <main className="flex-1 space-y-8 p-8 pt-6">

                {/* Search Hero Section */}
                <div className="flex flex-col items-center justify-center py-12 space-y-6">
                    <h1 className="text-4xl md:text-6xl font-bold tracking-tighter bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
                        RETARDIO EXPLORER
                    </h1>
                    <div className="w-full max-w-2xl relative">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                        <input
                            type="text"
                            placeholder="Search block height, hash, transaction, or address..."
                            className="w-full h-14 pl-12 pr-4 rounded-xl border border-border bg-card/80 text-lg shadow-2xl focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none transition-all placeholder:text-muted-foreground"
                        />
                    </div>
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
                        title="Difficulty"
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

                {/* Halving & Additional Info */}
                <div className="grid gap-6 md:grid-cols-2">
                    <Card className="bg-gradient-to-br from-card to-card-hover border-border">
                        <CardHeader>
                            <CardTitle>Halving Countdown</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex flex-col items-center justify-center space-y-6 pt-4">
                                <div className="text-center">
                                    <div className="text-5xl font-bold text-primary font-mono tracking-tighter drop-shadow-[0_0_15px_rgba(0,212,255,0.3)]">
                                        42,000
                                    </div>
                                    <p className="text-sm text-muted-foreground mt-2">Blocks Remaining</p>
                                </div>

                                <div className="w-full space-y-2">
                                    <div className="flex justify-between text-xs text-muted-foreground">
                                        <span>Progress (Era 1)</span>
                                        <span>80%</span>
                                    </div>
                                    <div className="h-3 w-full bg-black/40 rounded-full overflow-hidden border border-white/5">
                                        <div className="h-full bg-gradient-to-r from-primary to-secondary w-[80%] shadow-[0_0_15px_rgba(0,255,136,0.3)]" />
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="border-border">
                        <CardHeader>
                            <CardTitle>Market Info</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-4">
                                <div className="flex justify-between items-center p-3 rounded-lg bg-black/20">
                                    <span className="text-muted-foreground">Price</span>
                                    <span className="text-xl font-bold font-mono">$0.000420</span>
                                </div>
                                <div className="flex justify-between items-center p-3 rounded-lg bg-black/20">
                                    <span className="text-muted-foreground">Market Cap</span>
                                    <span className="text-xl font-bold font-mono">$220,500</span>
                                </div>
                                <div className="flex justify-between items-center p-3 rounded-lg bg-black/20">
                                    <span className="text-muted-foreground">Volume (24h)</span>
                                    <span className="text-xl font-bold font-mono">$69,420</span>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

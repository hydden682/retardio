import { Navbar } from "@/components/layout/navbar";
import { StatCard } from "@/components/dashboard/stat-card";
import { BlockTape } from "@/components/dashboard/block-tape";
import { NetworkActivityChart } from "@/components/dashboard/network-chart";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { api } from "@/lib/api";
import { Activity, Box, Coins, Server, Zap, Search } from "lucide-react";
import Link from "next/link";

export default async function Home() {
    const stats = await api.getStats();
    const latestBlocks = await api.getLatestBlocks();

    return (
        <div className="flex min-h-screen flex-col bg-background selection:bg-primary/30">
            <Navbar />

            {/* Mempool.space Style Block Stream */}
            <BlockTape blocks={latestBlocks} />

            <main className="flex-1 space-y-8 p-8 pt-6">

                {/* Search Hero */}
                <div className="flex flex-col items-center justify-center py-8 space-y-6">
                    <h1 className="text-4xl font-bold tracking-tighter text-white">
                        <span className="text-primary">RETARDIO</span> EXPLORER
                    </h1>
                    <div className="w-full max-w-2xl relative group">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground group-focus-within:text-primary transition-colors" />
                        <input
                            type="text"
                            placeholder="Search block, transaction, hash..."
                            className="w-full h-12 pl-12 pr-4 rounded-lg border border-border bg-card text-foreground focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all placeholder:text-muted-foreground"
                        />
                    </div>
                </div>

                {/* Chain Stats Section (Matched to User Image) */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 max-w-6xl mx-auto">
                    {/* Left Col: Stats Grid */}
                    <div className="grid grid-cols-2 gap-4">
                        <StatCard
                            title="TPS"
                            value="1,110"
                            subValue="Peak: 2.4k"
                            icon={Zap}
                        />
                        <StatCard
                            title="Block Height"
                            value={stats.height.toLocaleString()}
                            subValue="Latest"
                            icon={Box}
                        />
                        <StatCard
                            title="Hashrate"
                            value={stats.hashrate}
                            subValue="Network"
                            icon={Activity}
                        />
                        <StatCard
                            title="Supply"
                            value={stats.supply}
                            subValue="Total"
                            icon={Coins}
                        />
                    </div>

                    {/* Right Col: Activity Chart */}
                    <div className="flex flex-col">
                        <NetworkActivityChart />
                    </div>
                </div>

                {/* Recent Blocks List */}
                <div className="max-w-6xl mx-auto pt-8">
                    <Card className="border-border">
                        <CardHeader>
                            <CardTitle className="text-primary">Recent Blocks</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="space-y-0">
                                {latestBlocks.map((block) => (
                                    <div key={block.height} className="flex items-center justify-between border-b border-border py-4 last:border-0 hover:bg-card-hover px-4 -mx-4 transition-colors">
                                        <div className="flex items-center gap-4">
                                            <div className="h-10 w-10 flex items-center justify-center rounded bg-primary/10 text-primary font-bold">
                                                Bk
                                            </div>
                                            <div className="space-y-1">
                                                <Link href={`/block/${block.height}`} className="font-mono text-lg font-medium text-primary hover:underline">
                                                    #{block.height}
                                                </Link>
                                                <p className="text-xs text-muted-foreground">
                                                    {new Date(block.timestamp).toLocaleString()}
                                                </p>
                                            </div>
                                        </div>

                                        <div className="flex gap-8 text-right">
                                            <div>
                                                <div className="text-sm font-medium text-foreground">{block.tx_count} TXs</div>
                                                <div className="text-xs text-muted-foreground">{block.size.toLocaleString()} B</div>
                                            </div>
                                            <div>
                                                <div className="text-sm font-medium text-primary">{block.reward} RTC</div>
                                                <div className="text-xs text-muted-foreground">Reward + Fees</div>
                                            </div>
                                            <div className="min-w-[100px]">
                                                <Link href={`/miners/${block.miner}`} className="text-sm font-medium hover:text-white transition-colors">
                                                    {block.miner}
                                                </Link>
                                                <div className="text-xs text-muted-foreground">Miner</div>
                                            </div>
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

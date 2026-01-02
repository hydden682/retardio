import { Navbar } from "@/components/layout/navbar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { api } from "@/lib/api";
import Link from "next/link";
import { ArrowLeft, Box, CheckCircle, Clock, Database, Hash, User } from "lucide-react";

export default async function BlockPage({ params }: { params: { height: string } }) {
    const height = parseInt(params.height);
    const block = await api.getBlock(height);

    if (!block) return <div>Block not found</div>;

    return (
        <div className="flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1 p-8 pt-6 container max-w-5xl mx-auto">
                <div className="mb-6 flex items-center gap-4">
                    <Link href="/" className="p-2 rounded-full hover:bg-white/10 transition-colors">
                        <ArrowLeft className="h-5 w-5" />
                    </Link>
                    <h1 className="text-3xl font-bold font-mono tracking-tight flex items-center gap-3">
                        <Box className="h-8 w-8 text-primary" />
                        Block #{block.height}
                    </h1>
                </div>

                <div className="grid gap-6">
                    {/* Top Stats */}
                    <div className="grid md:grid-cols-3 gap-4">
                        <Card>
                            <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">Mined By</CardTitle></CardHeader>
                            <CardContent>
                                <div className="flex items-center gap-2">
                                    <User className="h-4 w-4 text-secondary" />
                                    <Link href={`/miners/${block.miner}`} className="font-medium hover:text-primary transition-colors">
                                        {block.miner}
                                    </Link>
                                </div>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">Transaction Count</CardTitle></CardHeader>
                            <CardContent>
                                <div className="flex items-center gap-2">
                                    <Database className="h-4 w-4 text-primary" />
                                    <span className="font-mono text-xl">{block.tx_count}</span>
                                </div>
                            </CardContent>
                        </Card>
                        <Card>
                            <CardHeader className="pb-2"><CardTitle className="text-sm text-muted-foreground">Confirmations</CardTitle></CardHeader>
                            <CardContent>
                                <div className="flex items-center gap-2">
                                    <CheckCircle className="h-4 w-4 text-secondary" />
                                    <span className="font-mono text-xl">120+</span>
                                </div>
                            </CardContent>
                        </Card>
                    </div>

                    {/* Main Details */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Details</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-6">
                            <div className="grid md:grid-cols-2 gap-6">
                                <div className="space-y-1">
                                    <span className="text-xs text-muted-foreground uppercase tracking-wider">Block Hash</span>
                                    <div className="flex items-center gap-2 bg-card-hover p-3 rounded-lg border border-border/50">
                                        <Hash className="h-4 w-4 text-muted-foreground" />
                                        <code className="text-sm break-all text-primary/80">{block.hash}</code>
                                    </div>
                                </div>
                                <div className="space-y-1">
                                    <span className="text-xs text-muted-foreground uppercase tracking-wider">Timestamp</span>
                                    <div className="flex items-center gap-2 bg-card-hover p-3 rounded-lg border border-border/50">
                                        <Clock className="h-4 w-4 text-muted-foreground" />
                                        <span className="text-sm">{new Date(block.timestamp).toUTCString()}</span>
                                    </div>
                                </div>
                                <div className="space-y-1">
                                    <span className="text-xs text-muted-foreground uppercase tracking-wider">Size</span>
                                    <div className="p-3">
                                        <span className="text-lg font-mono">{block.size.toLocaleString()} bytes</span>
                                    </div>
                                </div>
                                <div className="space-y-1">
                                    <span className="text-xs text-muted-foreground uppercase tracking-wider">Reward</span>
                                    <div className="p-3">
                                        <span className="text-lg font-mono text-secondary">{block.reward} RTC</span>
                                    </div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Transactions List Placeholder */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Transactions</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="py-8 text-center text-muted-foreground">
                                Transaction list loading...
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </main>
        </div>
    );
}

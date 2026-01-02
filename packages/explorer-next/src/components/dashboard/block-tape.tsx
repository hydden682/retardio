import Link from "next/link";
import { Block } from "@/lib/api";
import { cn } from "@/lib/utils";

interface BlockTapeProps {
    blocks: Block[];
}

export function BlockTape({ blocks }: BlockTapeProps) {
    return (
        <div className="w-full overflow-x-auto border-b border-border bg-card/50 backdrop-blur-sm">
            <div className="flex min-w-full p-4 gap-4">
                {blocks.map((block) => (
                    <Link
                        key={block.height}
                        href={`/block/${block.height}`}
                        className="flex-shrink-0 min-w-[200px] group"
                    >
                        <div className="rounded-lg border border-border bg-card p-4 transition-all hover:bg-card-hover hover:border-primary/50 group-hover:-translate-y-1 group-hover:shadow-lg hover:shadow-primary/10">
                            <div className="flex justify-between items-start mb-2">
                                <span className="text-sm font-mono text-muted-foreground">#{block.height}</span>
                                <span className="text-xs text-muted-foreground">{new Date(block.timestamp).toLocaleTimeString()}</span>
                            </div>
                            <div className="flex flex-col gap-1">
                                <span className="font-bold text-lg text-foreground group-hover:text-primary transition-colors">
                                    {block.tx_count} txs
                                </span>
                                <div className="flex justify-between items-center text-xs">
                                    <span className="text-muted-foreground truncate max-w-[80px]">{block.miner}</span>
                                    <span className="text-secondary font-mono">{block.size.toLocaleString()} B</span>
                                </div>
                            </div>
                            {/* Dripscan-style bottom accent */}
                            <div className="mt-3 h-1 w-full rounded-full bg-primary/20 overflow-hidden">
                                <div className="h-full bg-primary w-2/3" />
                            </div>
                        </div>
                    </Link>
                ))}
            </div>
        </div>
    );
}

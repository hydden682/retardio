import Link from "next/link";
import { Search } from "lucide-react";

export function Navbar() {
    return (
        <nav className="sticky top-0 z-50 w-full border-b border-border bg-background/80 backdrop-blur-xl">
            <div className="container flex h-16 items-center justify-between px-4">
                {/* Logo */}
                <Link href="/" className="flex items-center gap-2 font-bold text-xl tracking-tighter">
                    <span className="text-primary">RETARDIO</span>
                    <span className="text-muted-foreground">SCAN</span>
                </Link>

                {/* Search Bar (Desktop) */}
                <div className="hidden md:flex flex-1 mx-12 max-w-md">
                    <div className="relative w-full">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <input
                            type="text"
                            placeholder="Search by Block / Tx / Address..."
                            className="w-full h-10 rounded-full border border-border bg-card-hover pl-10 pr-4 text-sm outline-none focus:border-primary transition-colors hover:border-primary/50"
                        />
                    </div>
                </div>

                {/* Nav Links */}
                <div className="flex items-center gap-6 text-sm font-medium">
                    <Link href="/miners" className="hover:text-primary transition-colors">Miners</Link>
                    <Link href="/mempool" className="hover:text-primary transition-colors">Mempool</Link>
                    <Link href="https://retardiochain.com" target="_blank" className="text-muted-foreground hover:text-white transition-colors">Main Site</Link>

                    {/* Mobile Menu Trigger (Placeholder) */}
                    <button className="md:hidden text-muted-foreground">
                        <Search className="h-5 w-5" />
                    </button>
                </div>
            </div>
        </nav>
    );
}

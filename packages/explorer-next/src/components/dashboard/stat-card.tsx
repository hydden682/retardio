import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ArrowUpRight, ArrowDownRight, Activity } from "lucide-react";

interface StatCardProps {
    title: string;
    value: string;
    subValue?: string;
    trend?: "up" | "down" | "neutral";
    icon?: React.ElementType;
}

export function StatCard({ title, value, subValue, trend, icon: Icon }: StatCardProps) {
    return (
        <Card className="hover:border-primary/50 transition-colors">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                    {title}
                </CardTitle>
                {Icon ? <Icon className="h-4 w-4 text-muted-foreground" /> : <Activity className="h-4 w-4 text-muted-foreground" />}
            </CardHeader>
            <CardContent>
                <div className="text-2xl font-bold">{value}</div>
                {subValue && (
                    <div className="flex items-center text-xs text-muted-foreground mt-1">
                        {trend === "up" && <ArrowUpRight className="mr-1 h-3 w-3 text-secondary" />}
                        {trend === "down" && <ArrowDownRight className="mr-1 h-3 w-3 text-danger" />}
                        {subValue}
                    </div>
                )}
            </CardContent>
        </Card>
    );
}

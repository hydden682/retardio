"use client"

import { Bar, BarChart, ResponsiveContainer, Tooltip } from "recharts"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

const data = [
    { value: 400 },
    { value: 300 },
    { value: 200 },
    { value: 278 },
    { value: 189 },
    { value: 239 },
    { value: 349 },
]

export function NetworkActivityChart() {
    return (
        <Card className="col-span-4 border-yellow-500/20 shadow-[0_0_20px_rgba(255,215,0,0.05)]">
            <CardHeader>
                <CardTitle className="text-sm font-medium text-muted-foreground uppercase tracking-wider">Network Activity (24h)</CardTitle>
            </CardHeader>
            <CardContent className="pl-2">
                <ResponsiveContainer width="100%" height={120}>
                    <BarChart data={data}>
                        <Tooltip
                            cursor={{ fill: 'transparent' }}
                            contentStyle={{ backgroundColor: '#111', border: '1px solid #333', color: '#fff' }}
                        />
                        <Bar
                            dataKey="value"
                            fill="#FFD700"
                            radius={[4, 4, 0, 0]}
                            className="fill-primary hover:opacity-80 transition-opacity"
                        />
                    </BarChart>
                </ResponsiveContainer>
            </CardContent>
        </Card>
    )
}

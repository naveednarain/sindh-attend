import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Sindh Attend · University attendance', description: 'A clearer day on campus. Timetables, verified attendance, and academic insights.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}

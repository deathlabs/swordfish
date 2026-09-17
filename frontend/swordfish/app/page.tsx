import { CopilotSidebar } from "@copilotkit/react-core/v2";
import ProfileForm from "./components/ProfileForm";

export default function Home() {
  return (
    <main className="flex h-full">
      <section className="flex-1 border-r overflow-y-auto">
        <h1 className="p-4 text-xl font-semibold">Profile Setup</h1>
        <ProfileForm />
      </section>
      <section className="flex-1">
        <CopilotSidebar />
      </section>
    </main>
  );
}
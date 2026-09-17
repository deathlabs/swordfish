"use client";

import { useState } from "react";

export default function ProfileForm() {
  const [status, setStatus] = useState<"idle" | "submitting" | "done" | "error">("idle");

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("submitting");

    const form = e.currentTarget;
    const data = new FormData(form);

    try {

      const backendUrl = process.env.BACKEND_URL;
      
      const res = await fetch(`${backendUrl}/api/v1/emu/profiles/`, {
        method: "POST",
        body: data,
      });

      if (!res.ok) throw new Error(`Request failed with status ${res.status}`);
      setStatus("done");
      form.reset();
    } catch (err) {
      console.error(err);
      setStatus("error");
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4 p-4">
      <div>
        <label htmlFor="profileName" className="block text-sm font-medium">
          Profile Name
        </label>
        <input
          id="profileName"
          name="profileName"
          type="text"
          required
          className="mt-1 block w-full rounded border px-2 py-1"
        />
      </div>

      <div>
        <label htmlFor="dodId" className="block text-sm font-medium">
          DoD ID Number
        </label>
        <input
          id="dodId"
          name="dodId"
          type="text"
          inputMode="numeric"
          pattern="[0-9]{10}"
          title="10 digit DoD ID number"
          required
          className="mt-1 block w-full rounded border px-2 py-1"
        />
      </div>

      <div>
        <label htmlFor="apiKey" className="block text-sm font-medium">
          API Key
        </label>
        <input
          id="apiKey"
          name="apiKey"
          type="password"
          autoComplete="off"
          required
          className="mt-1 block w-full rounded border px-2 py-1"
        />
      </div>

      <div>
        <label htmlFor="certFile1" className="block text-sm font-medium">
          Private Key
        </label>
        <input
          id="certFile1"
          name="certFile1"
          type="file"
          accept=".key"
          required
          className="mt-1 block w-full text-sm"
        />
      </div>

      <div>
        <label htmlFor="certFile2" className="block text-sm font-medium">
          Public Key
        </label>
        <input
          id="certFile2"
          name="certFile2"
          type="file"
          accept=".pem,.crt,.cer,.p12,.pfx"
          required
          className="mt-1 block w-full text-sm"
        />
      </div>

      <button
        type="submit"
        disabled={status === "submitting"}
        className="rounded bg-black px-4 py-2 text-white disabled:opacity-50"
      >
        {status === "submitting" ? "Submitting..." : "Submit"}
      </button>

      {status === "done" && <p className="text-green-600 text-sm">Profile saved.</p>}
      {status === "error" && <p className="text-red-600 text-sm">Something went wrong. Try again.</p>}
    </form>
  );
}
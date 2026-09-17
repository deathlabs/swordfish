import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const formData = await req.formData();

  const profileName = formData.get("profileName");
  const dodId = formData.get("dodId");
  const apiKey = formData.get("apiKey");
  const certFile1 = formData.get("certFile1") as File | null;
  const certFile2 = formData.get("certFile2") as File | null;

  if (!profileName || !dodId || !apiKey || !certFile1 || !certFile2) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  const backendFormData = new FormData();
  
  backendFormData.append("profileName", profileName);
  backendFormData.append("dodId", dodId);
  backendFormData.append("apiKey", apiKey);
  backendFormData.append("certFile1", certFile1);
  backendFormData.append("certFile2", certFile2);

  const backendUrl = process.env.BACKEND_URL;

  const res = await fetch(`${backendUrl}/api/v1/emu/profiles`, {
    method: "POST",
    body: backendFormData,
  });

  if (!res.ok) {
    return NextResponse.json({ error: "Backend rejected the request" }, { status: 502 });
  }

  return NextResponse.json({ status: "ok" });
}
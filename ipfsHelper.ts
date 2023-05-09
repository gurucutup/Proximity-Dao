import axios from "axios";
import FormData from "form-data";

// Upload to IPFS and get back the uri
export async function uploadToIpfs(stringData: string): Promise<string> {
    let data = new FormData();
    data.append("path", stringData);

    const config = {
      method: "POST",
      url: "https://ipfs-0.aragon.network/api/v0/add",
      headers: {
        "X-API-KEY": "b477RhECf8s8sdM7XrkLBs2wHc4kCMwpbcFC55Kt"
      },
      data: data
    };
    
    const res = await axios(config);
    return "ipfs://" + res.data.Hash;
}
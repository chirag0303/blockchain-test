const express = require("express");
const bodyParser = require("body-parser");
const { Web3 } = require("web3");
const mongoose = require("mongoose");
require("dotenv").config();

const app = express();
app.use(bodyParser.json());

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URL;
// Connect MongoDB
mongoose
  .connect(MONGO_URI, { dbName: "supplyChain" })
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

// Shipment Schema
const shipmentSchema = new mongoose.Schema({
  shipmentId: String,
  description: String,
  status: String,
  events: [String],
});

const Shipment = mongoose.model("Shipment", shipmentSchema);

// --- BLOCKCHAIN SETUP ---
// const web3 = new Web3(new Web3.providers.HttpProvider(process.env.SEPOLIA_RPC_URL));
const web3 = new Web3(process.env.SEPOLIA_RPC_URL);
const contractABI = require("../supplychain_blockchain/out/supplyChain.sol/SupplyChain.json");
const contractAddress = process.env.CONTRACT_ADDRESS;
const adminAccount = web3.eth.accounts.privateKeyToAccount(process.env.ADMIN);
const updaterAccount = web3.eth.accounts.privateKeyToAccount(
  process.env.UPDATER
);
web3.eth.accounts.wallet.add(adminAccount);
web3.eth.accounts.wallet.add(updaterAccount);

const supplyChain = new web3.eth.Contract(contractABI.abi, contractAddress);

// Create new shipment
app.post("/shipment", async (req, res) => {
  try {
    const { shipmentId, description } = req.body;

    const tx = supplyChain.methods.createShipment(description);
    const receipt = await tx.send({
      from: updaterAccount.address,
      gas: 3000000,
    });

    const shipment = new Shipment({
      shipmentId,
      description,
      status: "Created",
      events: ["Shipment Created"],
    });
    await shipment.save();

    res.json({
      message: "Shipment created",
      receipt: JSON.parse(
        JSON.stringify(receipt, (key, value) =>
          typeof value === "bigint" ? value.toString() : value
        )
      ),
    });
    console.log("---------- Shipment Created -----------------");
    console.log(`Txn Hash: " ${receipt.transactionHash}\n 
        Block Number: ${receipt.blockNumber}\n 
        Gas Used: ${receipt.gasUsed.toString()}\n
        From: ${receipt.from}\n
        To: ${receipt.to}`);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to create shipment" });
  }
});

// Update shipment status
app.post("/update-status", async (req, res) => {
  try {
    const { shipmentId, status } = req.body;

    const tx = supplyChain.methods.updateStatus(
      shipmentId,
      status,
      "Updating status"
    );
    const receipt = await tx.send({
      from: updaterAccount.address,
      gas: 3000000,
    });

    await Shipment.findOneAndUpdate(
      { shipmentId },
      { $set: { status }, $push: { events: `Status updated to ${status}` } },
      { new: true }
    );

    res.json({ message: "Status updated", receipt });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update status" });
  }
});

// Get shipment history
app.get("/history/:shipmentId", async (req, res) => {
  try {
    const { shipmentId } = req.params;
    const shipment = await Shipment.findOne({ shipmentId });
    if (!shipment) return res.status(404).json({ error: "Shipment not found" });

    res.json(shipment);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch history" });
  }
});

// --- SERVER START ---
app.listen(PORT, () => {
  console.log(`SupplyChain API running on port ${PORT}`);
});

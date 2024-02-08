<template>
    <div class="flex flex-col size-full w-full overflow-hidden grow-0">
        <div
            id="chat"
            class="flex flex-col w-full bg-chat-green rounded-t-lg h-[75%] max-h-[310px] overflow-y-auto scrollbar-thumb-rounded"
        >
            <div v-for="(message, index) in chatHistoryAdvanced" :key="index" class="px-2">
                <span
                    v-if="checkIsSpectator(message.sender_id)"
                    class="text-black"
                    >{{ clipID(message.sender_id) }}: {{ message.message }}</span>
                <span
                    v-else
                    class="text-white"
                    >{{ clipID(message.sender_id) }}: {{ message.message }}</span>
            </div>
        </div>
        <div class="flex flex-col h-[25%] items-center">
            <input
                class="flex items-center self-stretch ttt-input-2 rounded-none p-2"
                v-model="currentMessage"
                @keypress.enter="sendMessage(currentMessage)"
            />
            <button
                class="ttt-button btn-3 rounded-none bg-chat-green"
                @click="sendMessage(currentMessage)"
            >
                SEND
            </button>
        </div>
    </div>
</template>


<script setup lang="ts">
	import { ref, onMounted } from "vue";
	import { useTicTacToeStore } from "../stores/ticTacToeStore";
	import { useTicTacToeHelpers  } from "../composables/tttHelper";

	interface ChatMessage {
 	message: string
 	sender_id: string
	}

	const { checkIsSpectator } = useTicTacToeHelpers()

	const chatHistoryAdvanced = ref(Array<ChatMessage>())

	const ticTacToeStore = useTicTacToeStore();

	const chatHistory = ref([""]);
	const currentMessage = ref("");

	const matchChannel = ticTacToeStore.matchChannel!;

	const sendMessage = (message: string) => {
		matchChannel.push("broadcast_message", { message: message });
		currentMessage.value = "";
	};

	onMounted(() => {
		matchChannel.on("game_message", (payload: { message: string; sender_id: string }) => {
			chatHistory.value.push(payload.message);
			chatHistoryAdvanced.value.push(payload);
			autoScroll();
		});
	});

	const autoScroll = () => {
		setTimeout(() => {
			var objDiv = document.querySelector("#chat > div:last-of-type");
			if (objDiv) objDiv.scrollIntoView();
		}, 250);
	};

	const clipID = (userID: string) => {
		return userID.slice(0, 6);
	};
	
</script>

<style>
	.ttt-input-2 {
		gap: 0.625rem;
		border: 1px solid var(--bg-color);
		background: var(--Light-Text-2);
		/* Text */
		color: var(--bg-color);
		font-family: Gilroy-Light;
		font-size: 1.5rem;
		font-style: normal;
		font-weight: 400;
		line-height: normal;
	}
</style>
